import SwiftUI

struct TeamCreateView: View {
    @State var viewModel = TeamViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0

    private let teamColors: [(name: String, hex: String)] = [
        ("青", "#007AFF"),
        ("赤", "#FF3B30"),
        ("緑", "#34C759"),
        ("オレンジ", "#FF9500"),
        ("紫", "#AF52DE"),
        ("ピンク", "#FF2D55"),
        ("黄", "#FFCC00"),
        ("水色", "#5AC8FA"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("チーム作成").tag(0)
                    Text("チーム参加").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    createTeamForm
                } else {
                    joinTeamForm
                }

                Spacer()
            }
            .navigationTitle("チーム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .onChange(of: viewModel.hasTeam) { _, hasTeam in
                if hasTeam {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Create Team Form

    private var createTeamForm: some View {
        Form {
            Section("チーム名") {
                TextField("チーム名を入力", text: $viewModel.newTeamName)
                    .textContentType(.organizationName)
            }

            Section("チームカラー") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(teamColors, id: \.hex) { color in
                        colorButton(name: color.name, hex: color.hex)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    Task {
                        await viewModel.createTeam()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("チームを作成する")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.newTeamName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
        }
    }

    // MARK: - Join Team Form

    private var joinTeamForm: some View {
        Form {
            Section("招待コード") {
                TextField("招待コードを入力", text: $viewModel.inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Section {
                Button {
                    Task {
                        await viewModel.joinTeamWithInviteCode()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("チームに参加する")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
        }
    }

    // MARK: - Color Picker

    @ViewBuilder
    private func colorButton(name: String, hex: String) -> some View {
        Button {
            viewModel.newTeamColor = hex
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 44, height: 44)
                    .overlay {
                        if viewModel.newTeamColor == hex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                                .fontWeight(.bold)
                        }
                    }
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TeamCreateView()
}
