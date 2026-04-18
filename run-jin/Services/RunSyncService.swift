import Foundation
import SwiftData
import Supabase
import Network

@MainActor
@Observable
final class RunSyncService: RunSyncServiceProtocol {
    private let modelContext: ModelContext
    private let h3Service: H3ServiceProtocol
    private let monitor = NWPathMonitor()
    private var isConnected = true

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
        try? modelContext.save()

        return responseDTO
    }

    /// ラン完了時にアップロード。セルデータがあればEdge Function、なければ直接upsert
    func uploadSession(_ session: RunSession) async throws {
        guard isConnected else { return }
        guard session.syncStatus == .pending else { return }

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
            try? modelContext.save()
        }
    }

    /// 未同期セッションを一括アップロード
    func syncPendingSessions() async {
        guard isConnected else { return }

        let pendingStatus = SyncStatus.pending
        let descriptor = FetchDescriptor<RunSession>(
            predicate: #Predicate { $0.syncStatus == pendingStatus }
        )

        guard let pendingSessions = try? modelContext.fetch(descriptor) else { return }

        for session in pendingSessions {
            do {
                try await uploadSession(session)
            } catch {
                // 個別の失敗は次回の同期で再試行
            }
        }
    }

    // MARK: - Private

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
