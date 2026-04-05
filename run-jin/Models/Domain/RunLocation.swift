import Foundation
import SwiftData

@Model
final class RunLocation {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var accuracy: Double
    var speed: Double

    var session: RunSession?

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date(),
        accuracy: Double = 0,
        speed: Double = 0
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.accuracy = accuracy
        self.speed = speed
    }
}
