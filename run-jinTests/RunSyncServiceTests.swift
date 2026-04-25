import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import run_jin

/// テスト用 `RunSyncBackend` モック。各メソッドでエラー注入・呼び出し記録ができる
final class MockRunSyncBackend: RunSyncBackendProtocol, @unchecked Sendable {
    var invokeSubmitRunError: Error?
    var invokeSubmitRunResponse = SubmitRunResponseDTO(
        sessionId: UUID().uuidString,
        cellsCaptured: 0,
        cellsOverridden: 0,
        totalCellsProcessed: 0
    )
    private(set) var invokeSubmitRunCalls: [SubmitRunRequestDTO] = []

    var upsertError: Error?
    private(set) var upsertCalls: [RunSessionDTO] = []

    var currentUserIdError: Error?
    var currentUserIdValue: UUID = UUID()

    func invokeSubmitRun(_ request: SubmitRunRequestDTO) async throws -> SubmitRunResponseDTO {
        invokeSubmitRunCalls.append(request)
        if let error = invokeSubmitRunError { throw error }
        return invokeSubmitRunResponse
    }

    func upsertRunSession(_ dto: RunSessionDTO) async throws {
        upsertCalls.append(dto)
        if let error = upsertError { throw error }
    }

    func currentUserId() async throws -> UUID {
        if let error = currentUserIdError { throw error }
        return currentUserIdValue
    }
}

/// テスト用 `H3ServiceProtocol` モック。RunSyncService が実際に呼ぶのは `centroid` のみ。
/// その他メソッドは「呼ばれたら即失敗」で silent bug を防ぐ。
final class MockH3Service: H3ServiceProtocol, @unchecked Sendable {
    func h3Index(for coordinate: CLLocationCoordinate2D) throws -> String {
        Issue.record("MockH3Service.h3Index called unexpectedly")
        return "unused"
    }

    func boundary(for h3Index: String) throws -> [CLLocationCoordinate2D] {
        Issue.record("MockH3Service.boundary called unexpectedly")
        return []
    }

    func h3Indices(for coordinates: [CLLocationCoordinate2D]) throws -> [String] {
        Issue.record("MockH3Service.h3Indices called unexpectedly")
        return []
    }

    func kRing(for h3Index: String, distance: Int) throws -> [String] {
        Issue.record("MockH3Service.kRing called unexpectedly")
        return []
    }

    func centroid(for h3Index: String) throws -> CLLocationCoordinate2D {
        // SubmitRunRequestDTO.from() がセルごとに呼ぶ
        CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454)
    }
}

enum TestSyncError: Error, LocalizedError {
    case simulatedNetwork
    case simulatedAuth

    var errorDescription: String? {
        switch self {
        case .simulatedNetwork: "Simulated network error"
        case .simulatedAuth: "Simulated auth error"
        }
    }
}

@MainActor
private struct TestHarness {
    let container: ModelContainer
    let context: ModelContext
    let backend: MockRunSyncBackend
    let service: RunSyncService
}

@MainActor
private func makeHarness(
    backend: MockRunSyncBackend = MockRunSyncBackend()
) throws -> TestHarness {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: RunSession.self, RunLocation.self,
        configurations: config
    )
    let context = container.mainContext

    let service = RunSyncService(
        modelContext: context,
        h3Service: MockH3Service(),
        backend: backend,
        startsNetworkMonitor: false
    )
    return TestHarness(container: container, context: context, backend: backend, service: service)
}

@Suite(.serialized)
struct RunSyncServiceTests {

    // MARK: - uploadSession

    @Test @MainActor func uploadSessionWithoutCellsCallsUpsertAndMarksSynced() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container

        let session = RunSession(startedAt: Date(), endedAt: Date())
        context.insert(session)
        try context.save()

        try await service.uploadSession(session)

        #expect(backend.upsertCalls.count == 1)
        #expect(session.syncStatus == .synced)
        #expect(session.lastSyncError == nil)
        #expect(session.syncRetryCount == 0)
    }

    @Test @MainActor func uploadSessionWithCellsDataCallsSubmitRun() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container

        let cells = [CellCaptureData(h3Index: "abc", distanceMeters: 100)]
        let cellsData = try JSONEncoder().encode(cells)
        backend.invokeSubmitRunResponse = SubmitRunResponseDTO(
            sessionId: UUID().uuidString,
            cellsCaptured: 3,
            cellsOverridden: 1,
            totalCellsProcessed: 4
        )

        let session = RunSession(startedAt: Date(), endedAt: Date(), cellsData: cellsData)
        context.insert(session)
        try context.save()

        try await service.uploadSession(session)

        #expect(backend.invokeSubmitRunCalls.count == 1)
        #expect(backend.upsertCalls.isEmpty)
        #expect(session.syncStatus == .synced)
        #expect(session.cellsCaptured == 3)
        #expect(session.cellsOverridden == 1)
    }

    @Test @MainActor func uploadSessionSkipsAlreadySyncedSession() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container

        let session = RunSession(startedAt: Date(), endedAt: Date(), syncStatus: .synced)
        context.insert(session)
        try context.save()

        try await service.uploadSession(session)

        #expect(backend.upsertCalls.isEmpty)
        #expect(backend.invokeSubmitRunCalls.isEmpty)
    }

    @Test @MainActor func uploadSessionProcessesFailedSession() async throws {
        // `.failed` ステータスのセッションは再度アップロード対象
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container

        let session = RunSession(
            startedAt: Date(),
            endedAt: Date(),
            syncStatus: .failed,
            lastSyncError: "prior",
            syncRetryCount: 2
        )
        context.insert(session)
        try context.save()

        try await service.uploadSession(session)

        #expect(backend.upsertCalls.count == 1)
        #expect(session.syncStatus == .synced)
        #expect(session.lastSyncError == nil)
        #expect(session.syncRetryCount == 0)
    }

    // MARK: - submitCompletedRun

    @Test @MainActor func submitCompletedRunSuccessMarksSynced() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container
        backend.invokeSubmitRunResponse = SubmitRunResponseDTO(
            sessionId: UUID().uuidString,
            cellsCaptured: 2,
            cellsOverridden: 0,
            totalCellsProcessed: 2
        )

        let session = RunSession(startedAt: Date(), endedAt: Date())
        context.insert(session)
        try context.save()

        await service.submitCompletedRun(session: session, cells: [])

        #expect(session.syncStatus == .synced)
        #expect(session.cellsCaptured == 2)
        #expect(session.lastSyncError == nil)
    }

    @Test @MainActor func submitCompletedRunFailureRecordsFailedState() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container
        backend.invokeSubmitRunError = TestSyncError.simulatedNetwork

        let session = RunSession(startedAt: Date(), endedAt: Date())
        context.insert(session)
        try context.save()

        await service.submitCompletedRun(session: session, cells: [])

        #expect(session.syncStatus == .failed)
        #expect(session.syncRetryCount == 1)
        #expect(session.lastSyncError == "Simulated network error")
    }

    // MARK: - syncPendingSessions predicate + retry

    @Test @MainActor func syncPendingSessionsSkipsSessionsAtRetryLimit() async throws {
        // retryCount >= 5 の .failed セッションは fetch 対象外
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container

        let exhausted = RunSession(
            startedAt: Date(),
            endedAt: Date(),
            syncStatus: .failed,
            syncRetryCount: 5
        )
        let retryable = RunSession(
            startedAt: Date(),
            endedAt: Date(),
            syncStatus: .failed,
            syncRetryCount: 4
        )
        let pending = RunSession(startedAt: Date(), endedAt: Date())
        context.insert(exhausted)
        context.insert(retryable)
        context.insert(pending)
        try context.save()

        await service.syncPendingSessions()

        // pending + retryable の 2 件だけ upsert される
        #expect(backend.upsertCalls.count == 2)
        #expect(exhausted.syncStatus == .failed)
        #expect(exhausted.syncRetryCount == 5)
    }

    @Test @MainActor func syncPendingSessionsRecordsFailureAndIncrementsRetry() async throws {
        let h = try makeHarness()
        let service = h.service
        let context = h.context
        let backend = h.backend
        _ = h.container
        backend.upsertError = TestSyncError.simulatedNetwork

        let session = RunSession(startedAt: Date(), endedAt: Date())
        context.insert(session)
        try context.save()

        await service.syncPendingSessions()

        #expect(session.syncStatus == .failed)
        #expect(session.syncRetryCount == 1)
        #expect(session.lastSyncError == "Simulated network error")
    }

    @Test @MainActor func syncPendingSessionsNoOpWhenEmpty() async throws {
        let h = try makeHarness()
        let service = h.service
        let backend = h.backend
        _ = h.container

        await service.syncPendingSessions()

        #expect(backend.upsertCalls.isEmpty)
        #expect(backend.invokeSubmitRunCalls.isEmpty)
    }
}
