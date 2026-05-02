import Foundation

/// HealthKit連携設定画面のViewModel。
///
/// トグル操作時に権限リクエストを発行し、失敗時はトグルを元に戻す。
@MainActor
@Observable
final class HealthKitSettingsViewModel {
    private let healthKitService: any HealthKitServiceProtocol
    private let settings: HealthKitIntegrationSettings
    private let analyticsService: any AnalyticsServiceProtocol

    /// 現在のトグル状態 (UI binding用)
    var isEnabled: Bool
    /// HealthKit側の権限状態
    var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    /// 権限要求中か
    var isRequesting: Bool = false
    /// 直近のエラー文言 (ローカライズ済み)
    var errorMessage: String?

    /// この端末でHealthKitが利用可能か (iPhone: true, iPad等: false)
    var isAvailable: Bool {
        healthKitService.isAvailable
    }

    init(
        healthKitService: any HealthKitServiceProtocol = DependencyContainer.shared.healthKitService,
        settings: HealthKitIntegrationSettings = .shared,
        analyticsService: any AnalyticsServiceProtocol = DependencyContainer.shared.analyticsService
    ) {
        self.healthKitService = healthKitService
        self.settings = settings
        self.analyticsService = analyticsService
        self.isEnabled = settings.isEnabled
    }

    /// 画面表示時に権限状態をロード
    func loadStatus() async {
        authorizationStatus = await healthKitService.authorizationStatus
        // 設定はONでも権限が拒否されている場合は実態と合わせる
        if isEnabled && authorizationStatus == .sharingDenied {
            isEnabled = false
            settings.isEnabled = false
        }
    }

    /// ユーザーがトグルを切り替えたときに呼ばれる
    func toggleIntegration(to newValue: Bool) async {
        errorMessage = nil

        if newValue {
            // ON → 権限要求
            guard healthKitService.isAvailable else {
                errorMessage = String(localized: "Apple Healthが利用できません")
                isEnabled = false
                return
            }

            isRequesting = true
            analyticsService.logEvent(
                .healthKitAuthorizationRequested,
                parameters: nil
            )

            do {
                try await healthKitService.requestAuthorization()
                authorizationStatus = await healthKitService.authorizationStatus
                settings.isEnabled = true
                isEnabled = true
                analyticsService.logEvent(
                    .healthKitAuthorizationGranted,
                    parameters: nil
                )
            } catch {
                errorMessage = String(localized: "Apple Healthへのアクセスが許可されていません")
                isEnabled = false
                settings.isEnabled = false
                analyticsService.logEvent(
                    .healthKitAuthorizationDenied,
                    parameters: nil
                )
            }
            isRequesting = false
        } else {
            // OFF → 設定のみ更新 (HealthKit側の権限は取り消せない)
            settings.isEnabled = false
            isEnabled = false
        }
    }
}
