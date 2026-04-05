import Foundation
import SwiftData

@Model
final class Territory {
    @Attribute(.unique) var h3Index: String
    var ownerId: String?
    var teamId: String?
    var capturedAt: Date
    var totalDistanceMeters: Double

    init(
        h3Index: String,
        ownerId: String? = nil,
        teamId: String? = nil,
        capturedAt: Date = Date(),
        totalDistanceMeters: Double = 0
    ) {
        self.h3Index = h3Index
        self.ownerId = ownerId
        self.teamId = teamId
        self.capturedAt = capturedAt
        self.totalDistanceMeters = totalDistanceMeters
    }
}
