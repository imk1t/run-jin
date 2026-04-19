import Foundation
import SwiftData
import Supabase
import Network
import os

@MainActor
@Observable
final class RunSyncService: RunSyncServiceProtocol {
    private let modelContext: ModelContext
    private let h3Service: H3ServiceProtocol
    private let monitor = NWPathMonitor()
    private var isConnected = true
    private var isSyncing = false
    private let logger = Logger(subsystem: "app.space.k1t.run-jin", category: "RunSyncService")

    /// `.failed` でも自動リトライする上限。超えたら手動リトライ待ち
    private let maxAutoRetryCount: Int = 5

    init(modelContext: ModelContext, h3Service: H3ServiceProtocol) {
        self.modelContext = modelContext
        self.h3Service = h3Service
        startNetworkMonitoring()
    }

    /// Edge Function経由でラン+セルデータを送信
    func submitRun(
        session: RunSession,
        cells: [CellCaptureData]
    ) async throws -> SubmitRunResponseDTO {
        let requestDTO = try SubmitRunRequestDTO.from(
            session: session,
            cells: cells,
            h3Service: h3Service
        )

        let responseDTO: SubmitRunResponseDTO = try await supabase.functions.invoke(
            "submit-run",
            options: .init(body: requestDTO)
        )

        session.cellsCaptured = responseDTO.cellsCaptured
        session.cellsOverridden = responseDTO.cellsOverridden
        session.syncStatus = .synced
        session.lastSyncError = nil
        session.syncRetryCount = 0
        try? modelContext.save()

        return responseDTO
    }

    /// ラン完了直後のアップロード。失敗時も `.failed` 状態に遷移させて観測可能にする。
    /// `RunningViewModel.submitInBackground` から利用。
    func submitCompletedRun(session: RunSession, cells: [CellCaptureData]) async {
        do {
            _ = try await submitRun(session: session, cells: cells)
            logger.info("Initial sync succeeded for session \(session.id.uuidString, privacy: .public)")
        } catch {
            recordSyncFailure(session: session, error: error)
        }
    }

    /// ラン完了時にアップロード。セルデータがあればEdge Function、なければ直接upsert
    func uploadSession(_ session: RunSession) async throws {
        guard isConnected else { return }
        guard session.syncStatus == .pending || session.syncStatus == .failed else { return }

        if let cellsData = session.cellsData,
           let cells = try? JSONDecoder().decode([CellCaptureData].self, from: cellsData) {
            _ = try await submitRun(session: session, cells: cells)
        } else {
            let userId = try await currentUserId()
            let dto = RunSessionDTO.from(session: session, userId: userId)

            try await supabase
                .from("run_sessions")
                .upsert(dto, onConflict: "idempotency_key")
                .execute()

            session.syncStatus = .synced
            session.lastSyncError = nil
            session.syncRetryCount = 0
            try? modelContext.save()
        }
    }

    /// 未同期セッションを一括アップロード。`NWPathMonitor` とアプリ起動時の 2 経路から呼ばれうるため
    /// 再入ガードで並行実行を防ぐ（未防止だと `syncRetryCount` が重複加算される恐れがある）。
    func syncPendingSessions() async {
        guard isConnected else { return }
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let pendingStatus = SyncStatus.pending
        let failedStatus = SyncStatus.failed
        let retryLimit = maxAutoRetryCount
        let descriptor = FetchDescriptor<RunSession>(
            predicate: #Predicate {
                $0.syncStatus == pendingStatus ||
                ($0.syncStatus == failedStatus && $0.syncRetryCount < retryLimit)
            }
        )

        guard let targets = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch pending sessions for sync")
            return
        }

        guard !targets.isEmpty else { return }
        logger.info("Starting sync for \(targets.count, privacy: .public) sessions")

        for session in targets {
            do {
                try await uploadSession(session)
                logger.info("Sync succeeded for session \(session.id.uuidString, privacy: .public)")
            } catch {
                recordSyncFailure(session: session, error: error)
            }
        }
    }

    // MARK: - Private

    private func recordSyncFailure(session: RunSession, error: Error) {
        session.syncStatus = .failed
        session.syncRetryCount += 1
        session.lastSyncError = error.localizedDescription
        try? modelContext.save()
        logger.error("Sync failed for session \(session.id.uuidString, privacy: .public) (attempt \(session.syncRetryCount, privacy: .public)): \(error.localizedDescription, privacy: .public)")
    }

    private func currentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        return session.user.id
    }

    private func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "run-jin.network-monitor")
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let connected = path.status == .satisfied
                self?.isConnected = connected
                if connected {
                    await self?.syncPendingSessions()
                }
            }
        }
        monitor.start(queue: queue)
    }
}
