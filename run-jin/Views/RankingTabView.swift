import SwiftUI

struct RankingTabView: View {
    @State private var viewModel = RankingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            scopePicker
            periodPicker
            rankingList
        }
        .navigationTitle("ランキング")
        .task {
            await viewModel.fetchRankings()
        }
    }

    // MARK: - Scope Picker (全国/都道府県/市区町村)

    private var scopePicker: some View {
        Picker("", selection: $viewModel.selectedScope) {
            ForEach(RankingScope.allCases, id: \.self) { scope in
                Text(scope.label).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: viewModel.selectedScope) { _, newScope in
            viewModel.onScopeChanged(newScope)
        }
    }

    // MARK: - Period Picker (週間/月間/累計)

    private var periodPicker: some View {
        Picker("", selection: $viewModel.selectedPeriod) {
            ForEach(RankingPeriod.allCases, id: \.self) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: viewModel.selectedPeriod) { _, newPeriod in
            viewModel.onPeriodChanged(newPeriod)
        }
    }

    // MARK: - Ranking List

    private var rankingList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("エラー", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("再試行") {
                        Task { await viewModel.fetchRankings() }
                    }
                }
            } else if viewModel.rankings.isEmpty {
                ContentUnavailableView {
                    Label("ランキングデータなし", systemImage: "trophy")
                } description: {
                    Text("まだランキングデータがありません")
                }
            } else {
                List {
                    // 自分の順位セクション
                    if let entry = viewModel.currentUserEntry,
                       let rank = viewModel.currentUserRank {
                        Section {
                            rankingRow(entry: entry, rank: rank, isCurrentUser: true)
                        } header: {
                            Text("あなたの順位")
                        }
                    }

                    // ランキング一覧
                    Section {
                        ForEach(Array(viewModel.rankings.enumerated()), id: \.element.id) { index, entry in
                            let isCurrentUser = entry.userId == viewModel.currentUserId
                            rankingRow(entry: entry, rank: index + 1, isCurrentUser: isCurrentUser)
                        }
                    } header: {
                        Text("ランキング")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Ranking Row

    private func rankingRow(entry: RankingEntryDTO, rank: Int, isCurrentUser: Bool) -> some View {
        HStack(spacing: 12) {
            rankBadge(rank: rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName.isEmpty ? String(localized: "匿名ランナー") : entry.displayName)
                    .font(.body)
                    .fontWeight(isCurrentUser ? .bold : .regular)
                Text(String(localized: "\(entry.cellsOwned)セル"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(localized: "\(entry.cellsOwned)"))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .listRowBackground(isCurrentUser ? Color.blue.opacity(0.1) : nil)
    }

    // MARK: - Rank Badge

    private func rankBadge(rank: Int) -> some View {
        Group {
            switch rank {
            case 1:
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                    .frame(width: 36)
            case 2:
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.gray)
                    .font(.title2)
                    .frame(width: 36)
            case 3:
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.brown)
                    .font(.title2)
                    .frame(width: 36)
            default:
                Text("\(rank)")
                    .font(.headline)
                    .monospacedDigit()
                    .frame(width: 36)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RankingTabView()
    }
}
