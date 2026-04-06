import SwiftUI
import SwiftData

struct AnonymousModeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AnonymousModeViewModel?

    var body: some View {
        Form {
            Section {
                if let viewModel {
                    Toggle(isOn: Binding(
                        get: { viewModel.isAnonymous },
                        set: { viewModel.toggleAnonymousMode($0) }
                    )) {
                        Label("匿名モード", systemImage: "eye.slash.fill")
                    }
                    .disabled(viewModel.isLoading)
                }
            } header: {
                Text("プライバシー設定")
            } footer: {
                Text("匿名モードをオンにすると、ランキングに表示されなくなり、テリトリーの所有者情報も他のユーザーには非公開になります。ランニングの記録やテリトリーの獲得は通常通り行えます。")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    AnonymousModeInfoRow(
                        icon: "trophy.fill",
                        title: "ランキング",
                        description: "ランキングから除外されます"
                    )
                    AnonymousModeInfoRow(
                        icon: "map.fill",
                        title: "テリトリー",
                        description: "所有者名が「匿名ランナー」と表示されます"
                    )
                    AnonymousModeInfoRow(
                        icon: "figure.run",
                        title: "ランニング記録",
                        description: "通常通り記録されます"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("匿名モードの影響")
            }

            if let errorMessage = viewModel?.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("匿名モード")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = AnonymousModeViewModel(modelContext: modelContext)
            }
        }
    }
}

private struct AnonymousModeInfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnonymousModeView()
            .modelContainer(for: UserProfile.self, inMemory: true)
    }
}
