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
            healthKitService: MockHealthKitService(),
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
            healthKitService: MockHealthKitService(),
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

    @Test @MainActor func finishPopulatesHeartRateFromHealthKit() async throws {
        let mockLocation = MockLocationService()
        let mockHealthKit = MockHealthKitService()
        mockHealthKit.stubHeartRateSummary = HealthKitHeartRateSummary(avgBpm: 140, maxBpm: 165)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self,
            configurations: config
        )
        let context = container.mainContext

        let service = RunSessionService(
            locationService: mockLocation,
            healthKitService: mockHealthKit,
            modelContext: context
        )

        await service.start()
        let session = await service.finish()

        #expect(session?.avgHeartRate == 140)
        #expect(session?.maxHeartRate == 165)
    }

    @Test @MainActor func finishCallsWriteWorkoutExactlyOnce() async throws {
        let mockLocation = MockLocationService()
        let mockHealthKit = MockHealthKitService()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self,
            configurations: config
        )
        let context = container.mainContext

        let service = RunSessionService(
            locationService: mockLocation,
            healthKitService: mockHealthKit,
            modelContext: context
        )

        await service.start()
        _ = await service.finish()

        #expect(mockHealthKit.writeWorkoutCallCount == 1)
    }

    @Test @MainActor func finishSucceedsWhenHealthKitThrows() async throws {
        let mockLocation = MockLocationService()
        let mockHealthKit = MockHealthKitService()
        mockHealthKit.shouldThrowOnWrite = true
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self,
            configurations: config
        )
        let context = container.mainContext

        let service = RunSessionService(
            locationService: mockLocation,
            healthKitService: mockHealthKit,
            modelContext: context
        )

        await service.start()
        let session = await service.finish()

        #expect(session != nil)
        #expect(service.state == .idle)
    }

    @Test @MainActor func privacyZoneLocationsAreExcludedFromSession() async throws {
        let mockLocation = MockLocationService()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RunSession.self, RunLocation.self, PrivacyZone.self,
            configurations: config
        )
        let context = container.mainContext

        // 自宅相当のプライバシーゾーン (半径 100m)
        let home = PrivacyZone(
            label: "home",
            centerLatitude: 35.6586,
            centerLongitude: 139.7454,
            radiusMeters: 100
        )
        context.insert(home)
        try context.save()

        let service = RunSessionService(
            locationService: mockLocation,
            healthKitService: MockHealthKitService(),
            modelContext: context
        )

        await service.start()

        // ゾーン内座標 (中心から ~5m)
        mockLocation.sendLocation(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.65864, longitude: 139.74545),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 3.0,
            timestamp: Date()
        ))
        // ゾーン外座標 (~1km 離れた点)
        mockLocation.sendLocation(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 35.6676, longitude: 139.7454),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 3.0,
            timestamp: Date().addingTimeInterval(5)
        ))

        try await Task.sleep(for: .milliseconds(200))

        let session = await service.finish()

        #expect(session?.locations.count == 1)
        #expect(session?.locations.first?.latitude == 35.6676)
    }
}
