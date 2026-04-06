import SwiftUI

@Observable
final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    let analyticsService: AnalyticsServiceProtocol

    private init() {
        // Use real Firebase analytics if GoogleService-Info.plist is present, otherwise use mock
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            analyticsService = AnalyticsService.shared
        } else {
            analyticsService = MockAnalyticsService()
        }
    }
}
