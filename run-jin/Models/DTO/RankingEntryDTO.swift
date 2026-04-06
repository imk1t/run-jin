import Foundation

struct RankingEntryDTO: Codable, Sendable, Identifiable {
    let userId: UUID
    let displayName: String
    let prefectureCode: Int?
    let municipalityCode: Int?
    let teamId: UUID?
    let cellsOwned: Int
    let totalDistance: Double
    let nationalRank: Int

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case prefectureCode = "prefecture_code"
        case municipalityCode = "municipality_code"
        case teamId = "team_id"
        case cellsOwned = "cells_owned"
        case totalDistance = "total_distance"
        case nationalRank = "national_rank"
    }
}
