import Foundation
import StoreKit

/// サブスクリプション画面のViewModel
@MainActor
@Observable
final class SubscriptionViewModel {
    // MARK: - Published State

    var products: [Product] = []
    var selectedProduct: Product?
    var subscriptionStatus: SubscriptionStatus = .unknown
    var isLoading = false
    var isPurchasing = false
    var errorMessage: String?
    var showSuccessAlert = false

    // MARK: - Computed Properties

    var isPremium: Bool {
        if case .subscribed = subscriptionStatus {
            return true
        }
        return false
    }

    var monthlyProduct: Product? {
        products.first { $0.id == StoreKitService.monthlyProductId }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == StoreKitService.yearlyProductId }
    }

    /// 年間プランの月額換算表示
    var yearlyMonthlyPrice: String? {
        guard let yearly = yearlyProduct else { return nil }
        let monthlyEquivalent = yearly.price / 12
        return yearly.priceFormatStyle.format(monthlyEquivalent)
    }

    // MARK: - Dependencies

    private let storeKitService: StoreKitServiceProtocol

    init(storeKitService: StoreKitServiceProtocol) {
        self.storeKitService = storeKitService
    }

    // MARK: - Actions

    /// 画面表示時に商品とステータスを読み込む
    func onAppear() async {
        isLoading = true
        defer { isLoading = false }

        await loadSubscriptionStatus()
        await loadProducts()
    }

    /// 商品を購入
    func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        errorMessage = nil

        defer { isPurchasing = false }

        do {
            let transaction = try await storeKitService.purchase(product)
            if transaction != nil {
                await loadSubscriptionStatus()
                showSuccessAlert = true
            }
        } catch {
            errorMessage = String(localized: "購入に失敗しました。もう一度お試しください。")
        }
    }

    /// 購入を復元
    func restore() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await storeKitService.restorePurchases()
            await loadSubscriptionStatus()
        } catch {
            errorMessage = String(localized: "復元に失敗しました。もう一度お試しください。")
        }
    }

    // MARK: - Private

    private func loadProducts() async {
        do {
            products = try await storeKitService.fetchProducts()
            // デフォルトで年額プランを選択
            selectedProduct = yearlyProduct ?? products.first
        } catch {
            errorMessage = String(localized: "商品情報の取得に失敗しました。")
        }
    }

    private func loadSubscriptionStatus() async {
        await storeKitService.refreshSubscriptionStatus()
        subscriptionStatus = await storeKitService.subscriptionStatus
    }
}
