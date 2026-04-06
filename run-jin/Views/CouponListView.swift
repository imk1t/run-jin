import SwiftUI

struct CouponListView: View {
    @State private var viewModel = CouponViewModel()
    let latitude: Double
    let longitude: Double

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("クーポンを検索中...")
            } else if viewModel.coupons.isEmpty {
                ContentUnavailableView(
                    "周辺にクーポンはありません",
                    systemImage: "ticket",
                    description: Text("走行ルート付近の提携店舗クーポンが表示されます")
                )
            } else {
                List(viewModel.coupons) { coupon in
                    CouponRow(coupon: coupon) {
                        viewModel.openCoupon(coupon)
                    }
                }
            }
        }
        .navigationTitle("周辺クーポン")
        .task {
            await viewModel.fetchNearbyCoupons(latitude: latitude, longitude: longitude)
        }
    }
}

private struct CouponRow: View {
    let coupon: CouponDTO
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coupon.storeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(coupon.title)
                        .font(.headline)
                    Text(coupon.discountText)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    if let expires = coupon.expiresAt {
                        Text("期限: \(expires.formatted(.dateTime.month().day()))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
