import Foundation

/// Placeholder ad service implementation.
/// Replace the body of each method with Google AdMob SDK calls when integrating.
final class AdService: AdServiceProtocol {
    // MARK: - State

    private let loadedAds: NSMutableSet = .init()

    // MARK: - AdServiceProtocol

    func isAdReady(_ format: AdFormat) async -> Bool {
        loadedAds.contains(format)
    }

    func loadAd(_ format: AdFormat) async throws {
        // TODO: Replace with GADInterstitialAd.load / GADBannerView preload
        // Simulate network delay for realistic placeholder behavior
        try await Task.sleep(for: .milliseconds(300))
        loadedAds.add(format)
    }

    func recordImpression(_ format: AdFormat) async {
        // TODO: Replace with AdMob impression tracking
        #if DEBUG
        print("[AdService] Recorded impression for \(format)")
        #endif
    }
}
