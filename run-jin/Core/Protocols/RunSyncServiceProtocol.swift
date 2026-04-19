import Foundation

protocol RunSyncServiceProtocol: Sendable {
    func uploadSession(_ session: RunSession) async throws
    func submitCompletedRun(session: RunSession, cells: [CellCaptureData]) async
    func syncPendingSessions() async
}
