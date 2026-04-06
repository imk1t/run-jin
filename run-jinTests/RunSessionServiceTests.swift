import Testing
import CoreLocation
import SwiftData
@testable import run_jin

/// テスト用のモックLocationService
final class MockLocationService: LocationServiceProtocol {
    let locationStream: AsyncStream<CLLocation>
    private let continuation: AsyncStream<CLLocation>.Continuation
    var authorizationStatus: LocationAuthorizationStatus = .authorizedAlways

    init() {
        let (stream, continuation) = AsyncStream<CLLocation>.makeStream()
        self.locationStream = stream
        self.continuation = continuation
    }

    func requestWhenInUseAuthorization() {}
    func requestAlwaysAuthorization() {}
    func startUpdating() {}
    func stopUpdating() {}

    func sendLocation(_ location: CLLocation) {
        continuation.yield(location)
    }

    func finish() {
        continuation.finish()
    }
}

struct RunSessionServiceTests {

    @Test func stateTransitions() async throws {
        #expect(RunSessionState.idle == .idle)
        #expect(RunSessionState.running == .running)
        #expect(RunSessionState.paused == .paused)
        #expect(RunSessionState.finished == .finished)
    }

    @Test func runStatsInitialValues() async throws {
        let stats = RunStats()
        #expect(stats.distanceMeters == 0)
        #expect(stats.durationSeconds == 0)
        #expect(stats.paceSecondsPerKm == nil)
        #expect(stats.calories == 0)
        #expect(stats.locationCount == 0)
    }

    @Test @MainActor func serviceStartTransition() async throws {
        let mockLocation = MockLocationService()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self,
            configurations: config
        )
        let context = container.mainContext

        let service = RunSessionService(
            locationService: mockLocation,
            modelContext: context
        )

        #expect(service.state == .idle)
        await service.start()
        #expect(service.state == .running)
        service.pause()
        #expect(service.state == .paused)
        await service.resume()
        #expect(service.state == .running)
        let session = await service.finish()
        #expect(session != nil)
        #expect(session?.distanceMeters == 0)
    }

    @Test @MainActor func finishResetsState() async throws {
        let mockLocation = MockLocationService()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self,
            configurations: config
        )
        let context = container.mainContext

        let service = RunSessionService(
            locationService: mockLocation,
            modelContext: context
        )

        await service.start()
        #expect(service.state == .running)

        // 少し待ってタイマーを進める
        try await Task.sleep(for: .milliseconds(100))

        let _ = await service.finish()

        // finish後にすべてのステートがリセットされていることを確認
        #expect(service.state == .idle)
        #expect(service.currentStats.durationSeconds == 0)
        #expect(service.currentStats.distanceMeters == 0)
        #expect(service.currentStats.calories == 0)
        #expect(service.routeCoordinates.isEmpty)
    }
}
