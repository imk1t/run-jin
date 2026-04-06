import Foundation

/// DTO for the `achievements` table joined with `user_achievements`.
struct AchievementDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: String
    let icon: String
    let thresholdValue: Double?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, icon
        case thresholdValue = "threshold_value"
        case createdAt = "created_at"
    }
}

/// DTO for `user_achievements` rows.
struct UserAchievementDTO: Codable, Sendable {
    let id: String
    let userId: String
    let achievementId: String
    let unlockedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
    }
}
