import Foundation

/// Ad format types supported by the app.
enum AdFormat: Sendable {
    case banner
    case interstitial
}

/// Protocol for ad loading and display services.
/// Premium users bypass ads entirely; this is checked at the call site.
protocol AdServiceProtocol: Sendable {
    /// Whether an ad of the given format is ready to display.
    func isAdReady(_ format: AdFormat) async -> Bool

    /// Preload an ad for the given format.
    func loadAd(_ format: AdFormat) async throws

    /// Record that an ad impression was shown.
    func recordImpression(_ format: AdFormat) async
}
