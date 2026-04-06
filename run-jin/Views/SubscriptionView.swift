import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @State private var viewModel: SubscriptionViewModel

    @Environment(\.dismiss) private var dismiss

    init(storeKitService: StoreKitServiceProtocol) {
        _viewModel = State(initialValue: SubscriptionViewModel(storeKitService: storeKitService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featureList
                    planSelector
                    purchaseButton
                    restoreButton
                    termsSection
                }
                .padding()
            }
            .navigationTitle("プレミアム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("購入完了", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("プレミアムプランへようこそ！全機能をお楽しみください。")
            }
            .task {
                await viewModel.onAppear()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow.gradient)

            Text("ラン陣 プレミアム")
                .font(.title.bold())

            Text("すべての機能を解放して\nランニングをもっと楽しもう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "chart.bar.fill", color: .blue, title: "詳細な分析", description: "ペース・距離・高低差の詳細レポート")
            featureRow(icon: "map.fill", color: .green, title: "テリトリー履歴", description: "過去の陣地変動を確認")
            featureRow(icon: "paintpalette.fill", color: .purple, title: "カスタマイズ", description: "マップテーマ・アイコンの変更")
            featureRow(icon: "eye.slash.fill", color: .orange, title: "広告非表示", description: "広告なしの快適な体験")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            if let monthly = viewModel.monthlyProduct {
                planCard(
                    product: monthly,
                    label: "月額プラン",
                    detail: nil,
                    isSelected: viewModel.selectedProduct?.id == monthly.id
                )
            }

            if let yearly = viewModel.yearlyProduct {
                planCard(
                    product: yearly,
                    label: "年額プラン",
                    detail: viewModel.yearlyMonthlyPrice.map {
                        String(localized: "月あたり\($0)")
                    },
                    isSelected: viewModel.selectedProduct?.id == yearly.id,
                    badge: "おトク"
                )
            }
        }
    }

    private func planCard(
        product: Product,
        label: LocalizedStringKey,
        detail: String?,
        isSelected: Bool,
        badge: LocalizedStringKey? = nil
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.headline)

                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title3.bold())
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await viewModel.purchase() }
        } label: {
            Group {
                if viewModel.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.isPremium ? "登録済み" : "プレミアムに登録")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.selectedProduct == nil || viewModel.isPurchasing || viewModel.isPremium)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("購入を復元") {
            Task { await viewModel.restore() }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    // MARK: - Terms

    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("サブスクリプションはiTunesアカウントに請求されます。")
            Text("期間終了の24時間前までにキャンセルしない限り自動更新されます。")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    SubscriptionView(storeKitService: StoreKitService())
}
