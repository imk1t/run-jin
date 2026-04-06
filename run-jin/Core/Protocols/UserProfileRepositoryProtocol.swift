import Foundation

struct UserProfileDTO: Codable, Sendable {
    var id: String
    var displayName: String
    var avatarUrl: String?
    var teamId: String?
    var prefectureCode: Int?
    var municipalityCode: Int?
    var isPremium: Bool
    var isAnonymous: Bool
    var totalDistanceMeters: Double
    var totalCellsOwned: Int

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case teamId = "team_id"
        case prefectureCode = "prefecture_code"
        case municipalityCode = "municipality_code"
        case isPremium = "is_premium"
        case isAnonymous = "is_anonymous"
        case totalDistanceMeters = "total_distance_meters"
        case totalCellsOwned = "total_cells_owned"
    }
}

struct UserProfileUpdateDTO: Codable, Sendable {
    var displayName: String?
    var prefectureCode: Int?
    var municipalityCode: Int?
    var avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case prefectureCode = "prefecture_code"
        case municipalityCode = "municipality_code"
        case avatarUrl = "avatar_url"
    }
}

protocol UserProfileRepositoryProtocol: Sendable {
    func fetchProfile(userId: String) async throws -> UserProfileDTO
    func updateProfile(userId: String, update: UserProfileUpdateDTO) async throws -> UserProfileDTO
    func uploadAvatar(userId: String, imageData: Data) async throws -> String
}
