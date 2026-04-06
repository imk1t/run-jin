import Foundation

struct PrivacyZoneDTO: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let label: String
    let centerLatitude: Double
    let centerLongitude: Double
    let radiusMeters: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case label
        case center
        case radiusMeters = "radius_meters"
    }

    init(
        id: UUID,
        userId: UUID,
        label: String,
        centerLatitude: Double,
        centerLongitude: Double,
        radiusMeters: Int
    ) {
        self.id = id
        self.userId = userId
        self.label = label
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.radiusMeters = radiusMeters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        label = try container.decode(String.self, forKey: .label)
        radiusMeters = try container.decode(Int.self, forKey: .radiusMeters)

        // Supabase returns PostGIS POINT as "POINT(lon lat)" or GeoJSON
        let centerString = try container.decode(String.self, forKey: .center)
        let parsed = Self.parsePoint(centerString)
        centerLatitude = parsed.latitude
        centerLongitude = parsed.longitude
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(label, forKey: .label)
        try container.encode(radiusMeters, forKey: .radiusMeters)
        // Encode center as PostGIS-compatible WKT POINT(lon lat)
        let pointWKT = "POINT(\(centerLongitude) \(centerLatitude))"
        try container.encode(pointWKT, forKey: .center)
    }

    /// PostGIS POINT(lon lat) 形式をパース
    private static func parsePoint(_ wkt: String) -> (latitude: Double, longitude: Double) {
        // Format: "POINT(lon lat)" or "SRID=4326;POINT(lon lat)"
        let cleaned = wkt
            .replacingOccurrences(of: "SRID=4326;", with: "")
            .replacingOccurrences(of: "POINT(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)
        let parts = cleaned.split(separator: " ")
        guard parts.count == 2,
              let lon = Double(parts[0]),
              let lat = Double(parts[1]) else {
            return (latitude: 0, longitude: 0)
        }
        return (latitude: lat, longitude: lon)
    }
}

extension PrivacyZoneDTO {
    /// SwiftData PrivacyZone モデルからDTOを生成
    static func from(zone: PrivacyZone, userId: UUID) -> PrivacyZoneDTO {
        PrivacyZoneDTO(
            id: zone.id,
            userId: userId,
            label: zone.label,
            centerLatitude: zone.centerLatitude,
            centerLongitude: zone.centerLongitude,
            radiusMeters: zone.radiusMeters
        )
    }
}
