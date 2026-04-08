import CoreLocation
import Foundation

// MARK: - Request

struct SubmitRunCellDTO: Codable, Sendable {
    let h3Index: String
    let distanceMeters: Double
    let lat: Double
    let lng: Double

    enum CodingKeys: String, CodingKey {
        case h3Index = "h3_index"
        case distanceMeters = "distance_meters"
        case lat
        case lng
    }
}

struct SubmitRunCoordinateDTO: Codable, Sendable {
    let lat: Double
    let lng: Double
}

struct SubmitRunRequestDTO: Codable, Sendable {
    let idempotencyKey: String
    let startedAt: String
    let endedAt: String
    let distanceMeters: Double
    let durationSeconds: Int
    let avgPaceSecondsPerKm: Double?
    let calories: Int?
    let routeCoordinates: [SubmitRunCoordinateDTO]?
    let cells: [SubmitRunCellDTO]

    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case avgPaceSecondsPerKm = "avg_pace_seconds_per_km"
        case calories
        case routeCoordinates = "route_coordinates"
        case cells
    }
}

extension SubmitRunRequestDTO {
    static func from(
        session: RunSession,
        cells: [CellCaptureData],
        h3Service: H3ServiceProtocol
    ) throws -> SubmitRunRequestDTO {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let locations = session.locations.sorted { $0.timestamp < $1.timestamp }

        let routeCoordinates: [SubmitRunCoordinateDTO]? = if locations.count >= 2 {
            locations.map { SubmitRunCoordinateDTO(lat: $0.latitude, lng: $0.longitude) }
        } else {
            nil
        }

        let cellDTOs = try cells.map { cell in
            let centroid = try h3Service.centroid(for: cell.h3Index)
            return SubmitRunCellDTO(
                h3Index: cell.h3Index,
                distanceMeters: cell.distanceMeters,
                lat: centroid.latitude,
                lng: centroid.longitude
            )
        }

        return SubmitRunRequestDTO(
            idempotencyKey: session.idempotencyKey,
            startedAt: formatter.string(from: session.startedAt),
            endedAt: formatter.string(from: session.endedAt ?? Date()),
            distanceMeters: session.distanceMeters,
            durationSeconds: session.durationSeconds,
            avgPaceSecondsPerKm: session.avgPaceSecondsPerKm,
            calories: session.calories,
            routeCoordinates: routeCoordinates,
            cells: cellDTOs
        )
    }
}

// MARK: - Response

struct SubmitRunResponseDTO: Codable, Sendable {
    let sessionId: String
    let cellsCaptured: Int
    let cellsOverridden: Int
    let totalCellsProcessed: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cellsCaptured = "cells_captured"
        case cellsOverridden = "cells_overridden"
        case totalCellsProcessed = "total_cells_processed"
    }
}
