import SwiftUI

struct HealthKitSettingsView: View {
    @State private var viewModel = HealthKitSettingsViewModel()

    var body: some View {
        Form {
            toggleSection
            statusSection
            descriptionSection
        }
        .navigationTitle("Appleヘルスケア")
        .task {
            await viewModel.loadStatus()
        }
    }

    private var toggleSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.isEnabled },
                set: { newValue in
                    Task { await viewModel.toggleIntegration(to: newValue) }
                }
            )) {
                Label("Apple Healthと連携", systemImage: "heart.fill")
                    .foregroundStyle(.pink)
            }
            .disabled(viewModel.isRequesting || !viewModel.isAvailable)

            if !viewModel.isAvailable {
                Text("Apple Healthが利用できません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var statusSection: some View {
        Section("状態") {
            HStack {
                Text("連携状態")
                Spacer()
                statusLabel
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch viewModel.authorizationStatus {
        case .sharingAuthorized where viewModel.isEnabled:
            Text("連携済み")
        case .sharingDenied:
            Text("アクセス拒否")
        case .notAvailable:
            Text("利用不可")
        default:
            Text("未連携")
        }
    }

    private var descriptionSection: some View {
        Section {
            Text("ランニングデータ（距離・時間・ルート・消費カロリー）をApple Healthに保存し、他のヘルスケアアプリから参照できるようにします")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HealthKitSettingsView()
    }
}
