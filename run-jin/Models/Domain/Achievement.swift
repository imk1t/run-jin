import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var achievementId: String
    var name: String
    var descriptionText: String
    var category: String
    var icon: String
    var unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    init(
        achievementId: String,
        name: String,
        descriptionText: String,
        category: String,
        icon: String = "star.fill",
        unlockedAt: Date? = nil
    ) {
        self.achievementId = achievementId
        self.name = name
        self.descriptionText = descriptionText
        self.category = category
        self.icon = icon
        self.unlockedAt = unlockedAt
    }
}
