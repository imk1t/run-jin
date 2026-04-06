import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

/// Firebase Analytics + Crashlytics implementation of AnalyticsServiceProtocol.
final class AnalyticsService: AnalyticsServiceProtocol {

    static let shared = AnalyticsService()

    private init() {}

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) {
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId ?? "")
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    func recordError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

/// No-op analytics service for previews and tests.
final class MockAnalyticsService: AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) {}
    func setUserId(_ userId: String?) {}
    func setUserProperty(_ value: String?, forName name: String) {}
    func recordError(_ error: Error) {}
}
