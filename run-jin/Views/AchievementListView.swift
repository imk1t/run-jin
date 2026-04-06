import SwiftUI
import SwiftData

struct AchievementListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AchievementViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress header
                progressHeader

                // Category filter
                categoryFilter

                // Achievement grid
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        error,
                        systemImage: "exclamationmark.triangle",
                        description: Text("下に引いて再読み込み")
                    )
                } else {
                    achievementGrid
                }
            }
            .padding()
        }
        .navigationTitle("実績")
        .refreshable {
            await viewModel.fetchAchievements(modelContext: modelContext)
        }
        .task {
            await viewModel.fetchAchievements(modelContext: modelContext)
        }
    }

    // MARK: - Subviews

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.unlockedCount) / \(viewModel.totalCount)")
                .font(.largeTitle.bold())
                .monospacedDigit()

            Text("解除済み")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.totalCount > 0 {
                ProgressView(
                    value: Double(viewModel.unlockedCount),
                    total: Double(viewModel.totalCount)
                )
                .tint(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: String(localized: "すべて"), category: nil)

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    categoryChip(label: category.displayName, category: category)
                }
            }
        }
    }

    private func categoryChip(label: String, category: AchievementCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var achievementGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.filteredAchievements, id: \.achievementId) { achievement in
                achievementCard(achievement)
            }
        }
    }

    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundStyle(achievement.isUnlocked ? .orange : .gray)
                .frame(height: 40)

            Text(achievement.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let date = achievement.unlockedAt {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color(.systemBackground) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        AchievementListView()
            .modelContainer(for: Achievement.self, inMemory: true)
    }
}
