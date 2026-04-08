import Foundation
import SwiftData

@Model
final class RunSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var distanceMeters: Double
    var durationSeconds: Int
    var avgPaceSecondsPerKm: Double?
    var calories: Int?
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var cellsCaptured: Int
    var cellsOverridden: Int
    var syncStatus: SyncStatus
    var idempotencyKey: String

    @Relationship(deleteRule: .cascade, inverse: \RunLocation.session)
    var locations: [RunLocation]

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        distanceMeters: Double = 0,
        durationSeconds: Int = 0,
        avgPaceSecondsPerKm: Double? = nil,
        calories: Int? = nil,
        avgHeartRate: Int? = nil,
        maxHeartRate: Int? = nil,
        cellsCaptured: Int = 0,
        cellsOverridden: Int = 0,
        syncStatus: SyncStatus = .pending,
        idempotencyKey: String = UUID().uuidString,
        locations: [RunLocation] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.avgPaceSecondsPerKm = avgPaceSecondsPerKm
        self.calories = calories
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.cellsCaptured = cellsCaptured
        self.cellsOverridden = cellsOverridden
        self.syncStatus = syncStatus
        self.idempotencyKey = idempotencyKey
        self.locations = locations
    }
}

enum SyncStatus: String, Codable {
    case pending
    case synced
    case conflict
}
