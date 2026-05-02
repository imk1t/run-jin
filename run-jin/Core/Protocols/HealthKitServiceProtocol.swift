import Foundation

/// HealthKitの権限状態
enum HealthKitAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case sharingDenied
    case sharingAuthorized
    /// iPadやHealthKit非対応端末などで利用不可
    case notAvailable
}

/// HealthKit書き込み用のワークアウトデータ (Sendable)。
/// SwiftData `@Model` を isolation 境界越しに渡すことを避けるための値型。
struct HealthKitWorkoutData: Sendable, Equatable {
    struct Location: Sendable, Equatable {
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let accuracy: Double
        let speed: Double
        let timestamp: Date
    }

    let startedAt: Date
    let endedAt: Date
    let distanceMeters: Double
    let calories: Int
    let locations: [Location]
}

/// HealthKit連携時のエラー
enum HealthKitError: Error, Sendable, Equatable {
    case notAvailable
    case authorizationDenied
    case saveFailed(String)
    case readFailed(String)
}

/// Apple Health (HealthKit) との連携プロトコル
protocol HealthKitServiceProtocol: Sendable {
    /// この端末でHealthKitが利用可能か (iPhone: true, iPad/一部Simulator: false)
    var isAvailable: Bool { get }

    /// 現在の権限状態
    var authorizationStatus: HealthKitAuthorizationStatus { get async }

    /// ユーザーにHealthKitの読み書き権限を要求する (OSの権限ダイアログを表示)
    func requestAuthorization() async throws

    /// ラン完了時にHKWorkout + HKWorkoutRouteを保存する
    /// - Parameter data: Sendable なワークアウトスナップショット
    func saveWorkout(from data: HealthKitWorkoutData) async throws

    /// HealthKitから最新の体重(kg)を取得する
    /// 失敗・未登録時はnil (カロリー計算は既定値にフォールバック)
    func fetchLatestBodyMassKg() async -> Double?
}
