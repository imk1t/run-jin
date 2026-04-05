import Foundation
import SwiftData

@Model
final class PrivacyZone {
    var id: UUID
    var label: String
    var centerLatitude: Double
    var centerLongitude: Double
    var radiusMeters: Int

    init(
        id: UUID = UUID(),
        label: String = "",
        centerLatitude: Double,
        centerLongitude: Double,
        radiusMeters: Int = 500
    ) {
        self.id = id
        self.label = label
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.radiusMeters = radiusMeters
    }
}
