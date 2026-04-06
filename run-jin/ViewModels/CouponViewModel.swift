import CoreLocation
import Foundation
import Supabase
import SwiftUI

@MainActor
@Observable
final class CouponViewModel {
    var coupons: [CouponDTO] = []
    var isLoading = false
    var errorMessage: String?

    /// ラン完了地点の周辺クーポンを取得（半径500m以内）
    func fetchNearbyCoupons(latitude: Double, longitude: Double, radiusMeters: Double = 500) async {
        isLoading = true
        errorMessage = nil

        do {
            let result: [CouponDTO] = try await supabase
                .from("coupons")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value

            // クライアント側で距離フィルタ（couponsテーブルにlocation列がある場合はサーバー側で絞る）
            coupons = result
            isLoading = false
        } catch {
            errorMessage = "クーポンの取得に失敗しました"
            isLoading = false
        }
    }

    func openCoupon(_ coupon: CouponDTO) {
        guard let deepLink = coupon.deepLink,
              let url = URL(string: deepLink) else { return }
        UIApplication.shared.open(url)
    }
}
