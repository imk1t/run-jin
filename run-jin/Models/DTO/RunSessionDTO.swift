import Foundation

struct RunSessionDTO: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let endedAt: Date?
    let distanceMeters: Double
    let durationSeconds: Int
    let avgPaceSecondsPerKm: Double?
    let calories: Int?
    let route: String? // PostGIS WKT形式 LINESTRING
    let cellsCaptured: Int
    let cellsOverridden: Int
    let idempotencyKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case avgPaceSecondsPerKm = "avg_pace_seconds_per_km"
        case calories
        case route
        case cellsCaptured = "cells_captured"
        case cellsOverridden = "cells_overridden"
        case idempotencyKey = "idempotency_key"
    }
}

extension RunSessionDTO {
    /// RunSession + RunLocationsからDTOを生成
    static func from(session: RunSession, userId: UUID) -> RunSessionDTO {
        let locations = session.locations.sorted { $0.timestamp < $1.timestamp }
        let route: String? = if locations.count >= 2 {
            "LINESTRING(" + locations.map { "\($0.longitude) \($0.latitude)" }.joined(separator: ",") + ")"
        } else {
            nil
        }

        return RunSessionDTO(
            id: session.id,
            userId: userId,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            distanceMeters: session.distanceMeters,
            durationSeconds: session.durationSeconds,
            avgPaceSecondsPerKm: session.avgPaceSecondsPerKm,
            calories: session.calories,
            route: route,
            cellsCaptured: session.cellsCaptured,
            cellsOverridden: session.cellsOverridden,
            idempotencyKey: session.idempotencyKey
        )
    }
}
