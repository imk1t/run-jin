import Foundation
import SwiftData
import Supabase

/// Categories for achievements displayed in the UI.
enum AchievementCategory: String, CaseIterable, Sendable {
    case territory
    case streak
    case distance
    case social

    var displayName: String {
        switch self {
        case .territory: String(localized: "陣地系")
        case .streak: String(localized: "継続系")
        case .distance: String(localized: "距離系")
        case .social: String(localized: "ソーシャル系")
        }
    }

    var icon: String {
        switch self {
        case .territory: "map.fill"
        case .streak: "flame.fill"
        case .distance: "figure.run"
        case .social: "person.3.fill"
        }
    }
}

@MainActor
@Observable
final class AchievementViewModel {
    private(set) var achievements: [Achievement] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Currently selected category filter. `nil` means show all.
    var selectedCategory: AchievementCategory?

    var filteredAchievements: [Achievement] {
        guard let category = selectedCategory else { return achievements }
        return achievements.filter { $0.category == category.rawValue }
    }

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var totalCount: Int {
        achievements.count
    }

    /// Fetches all achievements from Supabase and merges with user unlock status.
    func fetchAchievements(modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch master achievement list
            let allAchievements: [AchievementDTO] = try await supabase
                .from("achievements")
                .select()
                .order("category")
                .order("threshold_value")
                .execute()
                .value

            // Fetch user's unlocked achievements
            var unlockedMap: [String: Date] = [:]
            if let userId = try? await supabase.auth.session.user.id.uuidString {
                let userAchievements: [UserAchievementDTO] = try await supabase
                    .from("user_achievements")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                for ua in userAchievements {
                    unlockedMap[ua.achievementId] = formatter.date(from: ua.unlockedAt)
                }
            }

            // Map to domain models and persist to SwiftData
            var result: [Achievement] = []
            for dto in allAchievements {
                let achievement = Achievement(
                    achievementId: dto.id,
                    name: dto.name,
                    descriptionText: dto.description,
                    category: dto.category,
                    icon: dto.icon,
                    unlockedAt: unlockedMap[dto.id]
                )
                result.append(achievement)
            }

            // Replace local cache
            let descriptor = FetchDescriptor<Achievement>()
            let existing = try modelContext.fetch(descriptor)
            for item in existing {
                modelContext.delete(item)
            }
            for item in result {
                modelContext.insert(item)
            }
            try modelContext.save()

            achievements = result
        } catch {
            errorMessage = String(localized: "実績の取得に失敗しました")
        }

        isLoading = false
    }
}
