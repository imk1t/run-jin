import SwiftUI

struct TeamDetailView: View {
    @State var viewModel = TeamViewModel()

    let teamId: String

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.team == nil {
                ProgressView("読み込み中...")
            } else if let team = viewModel.team {
                teamContent(team)
            } else {
                ContentUnavailableView(
                    "チーム情報なし",
                    systemImage: "person.3.fill",
                    description: Text("チーム情報を取得できませんでした")
                )
            }
        }
        .navigationTitle("チーム")
        .task {
            await viewModel.loadTeam(teamId: teamId)
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
    }

    @ViewBuilder
    private func teamContent(_ team: TeamDTO) -> some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(Color(hex: team.color))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("招待コード: \(team.inviteCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("チーム統計") {
                LabeledContent("メンバー数") {
                    Text("\(viewModel.members.count)")
                }
                LabeledContent("合計セル数") {
                    Text("\(viewModel.totalTeamCells)")
                }
            }

            Section("メンバー") {
                if viewModel.members.isEmpty {
                    Text("メンバーがいません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.members, id: \.id) { member in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName.isEmpty
                                     ? String(localized: "名無しランナー")
                                     : member.displayName)
                                    .font(.body)
                                Text("\(member.totalCellsOwned) セル")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await viewModel.leaveTeam()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("チームを退出する")
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(teamId: "preview-id")
    }
}
