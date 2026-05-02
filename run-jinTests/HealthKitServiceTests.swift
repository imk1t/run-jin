import Testing
import Foundation
@testable import run_jin

/// テスト用のモックHealthKitService
final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    var isAvailable: Bool = true
    var authorizationStatusValue: HealthKitAuthorizationStatus = .notDetermined

    var requestAuthorizationCallCount = 0
    var saveWorkoutCallCount = 0
    var lastSavedData: HealthKitWorkoutData?
    var shouldThrowOnRequest = false
    var shouldThrowOnSave = false
    var bodyMassKg: Double? = nil

    var authorizationStatus: HealthKitAuthorizationStatus {
        get async { authorizationStatusValue }
    }

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        if shouldThrowOnRequest {
            throw HealthKitError.authorizationDenied
        }
        authorizationStatusValue = .sharingAuthorized
    }

    func saveWorkout(from data: HealthKitWorkoutData) async throws {
        saveWorkoutCallCount += 1
        lastSavedData = data
        if shouldThrowOnSave {
            throw HealthKitError.saveFailed("mock")
        }
    }

    func fetchLatestBodyMassKg() async -> Double? {
        bodyMassKg
    }
}

struct HealthKitServiceTests {

    @Test func authorizationStatusInitial() async throws {
        let mock = MockHealthKitService()
        let status = await mock.authorizationStatus
        #expect(status == .notDetermined)
    }

    @Test func requestAuthorizationSucceeds() async throws {
        let mock = MockHealthKitService()
        try await mock.requestAuthorization()
        #expect(mock.requestAuthorizationCallCount == 1)
        let status = await mock.authorizationStatus
        #expect(status == .sharingAuthorized)
    }

    @Test func requestAuthorizationThrowsWhenDenied() async throws {
        let mock = MockHealthKitService()
        mock.shouldThrowOnRequest = true

        await #expect(throws: HealthKitError.self) {
            try await mock.requestAuthorization()
        }
    }

    @Test func saveWorkoutPassesData() async throws {
        let mock = MockHealthKitService()
        let data = HealthKitWorkoutData(
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(600),
            distanceMeters: 1000,
            calories: 80,
            locations: []
        )
        try await mock.saveWorkout(from: data)
        #expect(mock.saveWorkoutCallCount == 1)
        #expect(mock.lastSavedData?.distanceMeters == 1000)
        #expect(mock.lastSavedData?.calories == 80)
    }

    @Test func saveWorkoutThrowsWhenConfigured() async throws {
        let mock = MockHealthKitService()
        mock.shouldThrowOnSave = true
        let data = HealthKitWorkoutData(
            startedAt: Date(),
            endedAt: Date(),
            distanceMeters: 0,
            calories: 0,
            locations: []
        )
        await #expect(throws: HealthKitError.self) {
            try await mock.saveWorkout(from: data)
        }
    }

    @Test func fetchBodyMassReturnsConfiguredValue() async throws {
        let mock = MockHealthKitService()
        mock.bodyMassKg = 70.5
        let kg = await mock.fetchLatestBodyMassKg()
        #expect(kg == 70.5)
    }

    @Test func fetchBodyMassReturnsNilByDefault() async throws {
        let mock = MockHealthKitService()
        let kg = await mock.fetchLatestBodyMassKg()
        #expect(kg == nil)
    }

    @Test func workoutDataIsEquatable() async throws {
        let now = Date()
        let data1 = HealthKitWorkoutData(
            startedAt: now,
            endedAt: now.addingTimeInterval(300),
            distanceMeters: 500,
            calories: 40,
            locations: [
                .init(latitude: 35.0, longitude: 139.0, altitude: 10, accuracy: 5, speed: 3.0, timestamp: now),
            ]
        )
        let data2 = data1
        #expect(data1 == data2)
    }
}

struct HealthKitSettingsViewModelTests {

    @Test @MainActor func toggleOnRequestsAuthorization() async throws {
        let mockHK = MockHealthKitService()
        let settings = HealthKitIntegrationSettings(userDefaults: UserDefaults(suiteName: "test-\(UUID())")!)
        let viewModel = HealthKitSettingsViewModel(
            healthKitService: mockHK,
            settings: settings,
            analyticsService: MockAnalyticsService()
        )

        await viewModel.toggleIntegration(to: true)

        #expect(mockHK.requestAuthorizationCallCount == 1)
        #expect(viewModel.isEnabled == true)
        #expect(settings.isEnabled == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test @MainActor func toggleOnRevertsWhenDenied() async throws {
        let mockHK = MockHealthKitService()
        mockHK.shouldThrowOnRequest = true
        let settings = HealthKitIntegrationSettings(userDefaults: UserDefaults(suiteName: "test-\(UUID())")!)
        let viewModel = HealthKitSettingsViewModel(
            healthKitService: mockHK,
            settings: settings,
            analyticsService: MockAnalyticsService()
        )

        await viewModel.toggleIntegration(to: true)

        #expect(viewModel.isEnabled == false)
        #expect(settings.isEnabled == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test @MainActor func toggleOffUpdatesSettings() async throws {
        let mockHK = MockHealthKitService()
        let settings = HealthKitIntegrationSettings(userDefaults: UserDefaults(suiteName: "test-\(UUID())")!)
        settings.isEnabled = true
        let viewModel = HealthKitSettingsViewModel(
            healthKitService: mockHK,
            settings: settings,
            analyticsService: MockAnalyticsService()
        )

        await viewModel.toggleIntegration(to: false)

        #expect(viewModel.isEnabled == false)
        #expect(settings.isEnabled == false)
    }

    @Test @MainActor func toggleOnFailsWhenNotAvailable() async throws {
        let mockHK = MockHealthKitService()
        mockHK.isAvailable = false
        let settings = HealthKitIntegrationSettings(userDefaults: UserDefaults(suiteName: "test-\(UUID())")!)
        let viewModel = HealthKitSettingsViewModel(
            healthKitService: mockHK,
            settings: settings,
            analyticsService: MockAnalyticsService()
        )

        await viewModel.toggleIntegration(to: true)

        #expect(viewModel.isEnabled == false)
        #expect(mockHK.requestAuthorizationCallCount == 0)
        #expect(viewModel.errorMessage != nil)
    }
}
