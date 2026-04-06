import SwiftData
import SwiftUI

@Observable
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    private var _locationService: LocationServiceProtocol?
    private var _runSessionService: RunSessionService?
    private var _storeKitService: StoreKitServiceProtocol?

    var locationService: LocationServiceProtocol {
        if _locationService == nil {
            _locationService = LocationService()
        }
        return _locationService!
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

    var storeKitService: StoreKitServiceProtocol {
        if _storeKitService == nil {
            _storeKitService = StoreKitService()
        }
        // Justified: lazy initialization guarantees non-nil
        return _storeKitService!
    }

    private init() {}
}
