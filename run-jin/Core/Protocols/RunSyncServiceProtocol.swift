import Foundation

protocol RunSyncServiceProtocol: Sendable {
    func uploadSession(_ session: RunSession) async throws
    func syncPendingSessions() async
}
