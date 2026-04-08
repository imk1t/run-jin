import Testing
import CoreLocation
import Foundation
@testable import run_jin

/// テスト用のモックHealthKitService
final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    var isHealthDataAvailable: Bool = true
    private(set) var writeAuthorizationStatus: HealthKitAuthorizationStatus = .notDetermined

    var stubBodyMassKg: Double?
    var stubHeartRateSummary: HealthKitHeartRateSummary?
    var shouldThrowOnRequest: Bool = false
    var shouldThrowOnWrite: Bool = false

    private(set) var requestAuthorizationCallCount: Int = 0
    private(set) var refreshAuthorizationStatusCallCount: Int = 0
    private(set) var writeWorkoutCallCount: Int = 0
    private(set) var lastWrittenWorkout: WorkoutWriteData?
    private(set) var lastWriteLocations: [CLLocation] = []

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        if shouldThrowOnRequest {
            throw HealthKitError.notAvailable
        }
        writeAuthorizationStatus = .sharingAuthorized
    }

    func refreshAuthorizationStatus() {
        refreshAuthorizationStatusCallCount += 1
    }

    func fetchLatestBodyMassKg() async -> Double? {
        stubBodyMassKg
    }

    func fetchHeartRateSummary(start: Date, end: Date) async -> HealthKitHeartRateSummary? {
        stubHeartRateSummary
    }

    func writeWorkout(_ workout: WorkoutWriteData, locations: [CLLocation]) async throws {
        writeWorkoutCallCount += 1
        lastWrittenWorkout = workout
        lastWriteLocations = locations
        if shouldThrowOnWrite {
            throw HealthKitError.writeFailed("mock")
        }
    }
}

struct HealthKitServiceTests {

    @Test func mockStartsNotDetermined() async throws {
        let mock = MockHealthKitService()
        #expect(mock.writeAuthorizationStatus == .notDetermined)
    }

    @Test func requestAuthorizationTransitionsToAuthorized() async throws {
        let mock = MockHealthKitService()
        try await mock.requestAuthorization()
        #expect(mock.requestAuthorizationCallCount == 1)
        #expect(mock.writeAuthorizationStatus == .sharingAuthorized)
    }

    @Test func requestAuthorizationThrowsWhenConfigured() async throws {
        let mock = MockHealthKitService()
        mock.shouldThrowOnRequest = true
        await #expect(throws: HealthKitError.self) {
            try await mock.requestAuthorization()
        }
    }

    @Test func fetchBodyMassReturnsStubValue() async throws {
        let mock = MockHealthKitService()
        mock.stubBodyMassKg = 72.5
        let result = await mock.fetchLatestBodyMassKg()
        #expect(result == 72.5)
    }

    @Test func fetchBodyMassReturnsNilByDefault() async throws {
        let mock = MockHealthKitService()
        let result = await mock.fetchLatestBodyMassKg()
        #expect(result == nil)
    }

    @Test func fetchHeartRateReturnsStubSummary() async throws {
        let mock = MockHealthKitService()
        mock.stubHeartRateSummary = HealthKitHeartRateSummary(avgBpm: 145, maxBpm: 172)
        let result = await mock.fetchHeartRateSummary(start: Date(), end: Date())
        #expect(result?.avgBpm == 145)
        #expect(result?.maxBpm == 172)
    }

    @Test func fetchHeartRateReturnsNilByDefault() async throws {
        let mock = MockHealthKitService()
        let result = await mock.fetchHeartRateSummary(start: Date(), end: Date())
        #expect(result == nil)
    }

    @Test func writeWorkoutCapturesDataAndLocations() async throws {
        let mock = MockHealthKitService()
        let start = Date()
        let workout = WorkoutWriteData(
            startDate: start,
            endDate: start.addingTimeInterval(60),
            distanceMeters: 200,
            calories: 15
        )
        let locations = [
            CLLocation(latitude: 35.0, longitude: 139.0),
            CLLocation(latitude: 35.001, longitude: 139.001),
        ]
        try await mock.writeWorkout(workout, locations: locations)
        #expect(mock.writeWorkoutCallCount == 1)
        #expect(mock.lastWrittenWorkout?.distanceMeters == 200)
        #expect(mock.lastWriteLocations.count == 2)
    }

    @Test func writeWorkoutThrowsWhenConfigured() async throws {
        let mock = MockHealthKitService()
        mock.shouldThrowOnWrite = true
        let workout = WorkoutWriteData(
            startDate: Date(),
            endDate: Date(),
            distanceMeters: 0,
            calories: nil
        )
        await #expect(throws: HealthKitError.self) {
            try await mock.writeWorkout(workout, locations: [])
        }
    }
}
