import SwiftData
import SwiftUI

@Observable
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    let analyticsService: AnalyticsServiceProtocol

    private var _authService: (any AuthServiceProtocol)?
    private var _locationService: LocationServiceProtocol?
    private var _runSessionService: RunSessionService?
    private var _storeKitService: StoreKitServiceProtocol?
    private var _voiceFeedbackService: VoiceFeedbackServiceProtocol?
    private var _healthKitService: (any HealthKitServiceProtocol)?

    var authService: any AuthServiceProtocol {
        if _authService == nil {
            _authService = AuthService()
        }
        return _authService!
    }

    var locationService: LocationServiceProtocol {
        if _locationService == nil {
            _locationService = LocationService()
        }
        return _locationService!
    }

    var voiceFeedbackService: VoiceFeedbackServiceProtocol {
        if _voiceFeedbackService == nil {
            _voiceFeedbackService = VoiceFeedbackService()
        }
        return _voiceFeedbackService!
    }

    var storeKitService: StoreKitServiceProtocol {
        if _storeKitService == nil {
            _storeKitService = StoreKitService()
        }
        return _storeKitService!
    }

    var healthKitService: any HealthKitServiceProtocol {
        if _healthKitService == nil {
            _healthKitService = HealthKitService()
        }
        return _healthKitService!
    }

    @MainActor
    func runSessionService(modelContext: ModelContext) -> RunSessionService {
        if _runSessionService == nil {
            _runSessionService = RunSessionService(
                locationService: locationService,
                healthKitService: healthKitService,
                healthKitSettings: .shared,
                modelContext: modelContext
            )
        }
        return _runSessionService!
    }

    private init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            analyticsService = AnalyticsService.shared
        } else {
            analyticsService = MockAnalyticsService()
        }
    }
}
