import Foundation

/// Protocol defining the analytics service interface.
/// All analytics implementations (Firebase, mock, etc.) must conform to this protocol.
protocol AnalyticsServiceProtocol: Sendable {
    /// Log a custom event with optional parameters.
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]?)

    /// Set the current user ID for analytics attribution.
    func setUserId(_ userId: String?)

    /// Set a user property for segmentation.
    func setUserProperty(_ value: String?, forName name: String)

    /// Record a non-fatal error to Crashlytics.
    func recordError(_ error: Error)
}

extension AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent) {
        logEvent(event, parameters: nil)
    }
}
