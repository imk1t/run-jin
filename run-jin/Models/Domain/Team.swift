import Foundation
import SwiftData

@Model
final class Team {
    @Attribute(.unique) var id: String
    var name: String
    var color: String
    var inviteCode: String
    var memberCount: Int
    var totalCellsOwned: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        color: String = "#007AFF",
        inviteCode: String = "",
        memberCount: Int = 0,
        totalCellsOwned: Int = 0
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.inviteCode = inviteCode
        self.memberCount = memberCount
        self.totalCellsOwned = totalCellsOwned
    }
}
