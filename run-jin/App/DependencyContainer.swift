import SwiftData
import SwiftUI

@Observable
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    private var _locationService: LocationServiceProtocol?
    private var _runSessionService: RunSessionService?
    private var _voiceFeedbackService: VoiceFeedbackServiceProtocol?

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

    @MainActor
    func runSessionService(modelContext: ModelContext) -> RunSessionService {
        if _runSessionService == nil {
            _runSessionService = RunSessionService(
                locationService: locationService,
                modelContext: modelContext
            )
        }
        return _runSessionService!
    }

    private init() {}
}
