import Foundation
import StoreKit

/// サブスクリプションの状態
enum SubscriptionStatus: Sendable, Equatable {
    case unknown
    case notSubscribed
    case subscribed(productId: String, expiresDate: Date?)
    case expired
    case revoked
}

/// StoreKit 2 によるサブスクリプション管理プロトコル
protocol StoreKitServiceProtocol: Sendable {
    /// 現在のサブスクリプション状態
    var subscriptionStatus: SubscriptionStatus { get async }

    /// 利用可能なサブスクリプション商品を取得
    func fetchProducts() async throws -> [Product]

    /// 商品を購入
    func purchase(_ product: Product) async throws -> Transaction?

    /// 購入の復元
    func restorePurchases() async throws

    /// トランザクション更新のリスニングを開始
    func startTransactionListener() async

    /// 現在のエンタイトルメントを確認してステータスを更新
    func refreshSubscriptionStatus() async
}
