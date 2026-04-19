import Testing
import Foundation
@testable import run_jin

/// StoreKit の Product / Transaction は StoreKitTest フレームワーク必須のため、
/// 本ファイルでは StoreKit に触れない pure logic（初期状態、enum の等価性）のみ検証する。
/// 購入フロー/リストアの統合テストは `.storekit` Configuration を追加した別 PR で対応予定。
struct StoreKitServiceTests {

    @Test func initialSubscriptionStatusIsUnknown() async throws {
        let service = StoreKitService()
        let status = await service.subscriptionStatus
        #expect(status == .unknown)
    }

    @Test func subscriptionStatusEnumEquality() {
        #expect(SubscriptionStatus.unknown == .unknown)
        #expect(SubscriptionStatus.notSubscribed == .notSubscribed)
        #expect(SubscriptionStatus.expired == .expired)
        #expect(SubscriptionStatus.revoked == .revoked)

        let expiry = Date(timeIntervalSince1970: 1_800_000_000)
        let a = SubscriptionStatus.subscribed(productId: "com.example.monthly", expiresDate: expiry)
        let b = SubscriptionStatus.subscribed(productId: "com.example.monthly", expiresDate: expiry)
        let c = SubscriptionStatus.subscribed(productId: "com.example.yearly", expiresDate: expiry)
        #expect(a == b)
        #expect(a != c)
    }

    @Test func subscriptionStatusDistinctCases() {
        #expect(SubscriptionStatus.unknown != .notSubscribed)
        #expect(SubscriptionStatus.expired != .revoked)
        #expect(SubscriptionStatus.notSubscribed != .expired)
    }
}
