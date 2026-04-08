import SwiftData
import SwiftUI

@Observable
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    let analyticsService: AnalyticsServiceProtocol

    private var _authService: (any AuthServiceProtocol)?
    private var _locationService: LocationServiceProtocol?
    private var _healthKitService: HealthKitServiceProtocol?
    private var _runSessionService: RunSessionService?
    private var _storeKitService: StoreKitServiceProtocol?
    private var _voiceFeedbackService: VoiceFeedbackServiceProtocol?

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

    var healthKitService: HealthKitServiceProtocol {
        if _healthKitService == nil {
            _healthKitService = HealthKitService()
        }
        return _healthKitService!
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

    @MainActor
    func runSessionService(modelContext: ModelContext) -> RunSessionService {
        if _runSessionService == nil {
            _runSessionService = RunSessionService(
                locationService: locationService,
                healthKitService: healthKitService,
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
