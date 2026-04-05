import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var displayName: String
    var avatarURL: String?
    var teamId: String?
    var prefectureCode: Int?
    var municipalityCode: Int?
    var isPremium: Bool
    var isAnonymous: Bool
    var totalDistanceMeters: Double
    var totalCellsOwned: Int

    init(
        id: String,
        displayName: String = "",
        avatarURL: String? = nil,
        teamId: String? = nil,
        prefectureCode: Int? = nil,
        municipalityCode: Int? = nil,
        isPremium: Bool = false,
        isAnonymous: Bool = false,
        totalDistanceMeters: Double = 0,
        totalCellsOwned: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.teamId = teamId
        self.prefectureCode = prefectureCode
        self.municipalityCode = municipalityCode
        self.isPremium = isPremium
        self.isAnonymous = isAnonymous
        self.totalDistanceMeters = totalDistanceMeters
        self.totalCellsOwned = totalCellsOwned
    }
}
