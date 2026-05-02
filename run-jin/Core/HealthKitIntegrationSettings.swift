import Foundation

/// HealthKit連携のユーザー設定 (ON/OFF)。
///
/// UserDefaultsに永続化され、アプリ起動時に復元される。
/// ユーザーが設定画面でトグルを切り替えると値が更新される。
@MainActor
@Observable
final class HealthKitIntegrationSettings {
    static let shared = HealthKitIntegrationSettings()

    private let userDefaults: UserDefaults
    private let key = "healthkit_integration_enabled"

    /// HealthKit連携が有効か。既定値はfalse (opt-in)。
    var isEnabled: Bool {
        didSet {
            userDefaults.set(isEnabled, forKey: key)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isEnabled = userDefaults.bool(forKey: key)
    }
}
