import Foundation
import SwiftData
import Supabase
import Network

@MainActor
@Observable
final class RunSyncService: RunSyncServiceProtocol {
    private let modelContext: ModelContext
    private let monitor = NWPathMonitor()
    private var isConnected = true

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        startNetworkMonitoring()
    }

    /// ラン完了時にアップロード。オフラインの場合はpendingのまま
    func uploadSession(_ session: RunSession) async throws {
        guard isConnected else { return }
        guard session.syncStatus == .pending else { return }

        let userId = try await currentUserId()
        let dto = RunSessionDTO.from(session: session, userId: userId)

        try await supabase
            .from("run_sessions")
            .upsert(dto, onConflict: "idempotency_key")
            .execute()

        session.syncStatus = .synced
        try? modelContext.save()
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
