import Foundation
import os
import StoreKit

/// StoreKit 2 サブスクリプション管理サービス
final class StoreKitService: StoreKitServiceProtocol {
    /// App Store Connect で登録するプロダクトID
    static let monthlyProductId = "com.runjin.premium.monthly"
    static let yearlyProductId = "com.runjin.premium.yearly"

    private static let productIds: Set<String> = [
        monthlyProductId,
        yearlyProductId,
    ]

    private let logger = Logger(subsystem: "com.runjin", category: "StoreKitService")

    private let _status: OSAllocatedUnfairLock<SubscriptionStatus>
    private var transactionListenerTask: Task<Void, Never>?

    var subscriptionStatus: SubscriptionStatus {
        get async {
            _status.withLock { $0 }
        }
    }

    init() {
        _status = OSAllocatedUnfairLock(initialState: .unknown)
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - StoreKitServiceProtocol

    func fetchProducts() async throws -> [Product] {
        let products = try await Product.products(for: Self.productIds)
        logger.info("Fetched \(products.count) products")
        return products.sorted { $0.price < $1.price }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshSubscriptionStatus()
            logger.info("Purchase successful: \(product.id)")
            return transaction

        case .userCancelled:
            logger.info("Purchase cancelled by user")
            return nil

        case .pending:
            logger.info("Purchase pending approval")
            return nil

        @unknown default:
            logger.warning("Unknown purchase result")
            return nil
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshSubscriptionStatus()
        logger.info("Purchases restored")
    }

    func startTransactionListener() async {
        // 初回ステータス確認
        await refreshSubscriptionStatus()

        // バックグラウンドでトランザクション更新をリスニング
        transactionListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.refreshSubscriptionStatus()
                    self.logger.info("Transaction updated: \(transaction.productID)")
                } catch {
                    self.logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func refreshSubscriptionStatus() async {
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productType == .autoRenewable {
                    if transaction.revocationDate != nil {
                        updateStatus(.revoked)
                        return
                    }

                    if let expirationDate = transaction.expirationDate,
                       expirationDate < Date() {
                        updateStatus(.expired)
                        return
                    }

                    updateStatus(.subscribed(
                        productId: transaction.productID,
                        expiresDate: transaction.expirationDate
                    ))
                    foundActive = true
                }
            } catch {
                logger.error("Entitlement verification failed: \(error.localizedDescription)")
            }
        }

        if !foundActive {
            updateStatus(.notSubscribed)
        }
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func updateStatus(_ status: SubscriptionStatus) {
        _status.withLock { $0 = status }
    }
}
