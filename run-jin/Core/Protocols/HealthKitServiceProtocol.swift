import CoreLocation
import Foundation

enum HealthKitAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case sharingDenied
    case sharingAuthorized
    case notAvailable
}

struct HealthKitHeartRateSummary: Sendable, Equatable {
    let avgBpm: Int
    let maxBpm: Int
}

/// `RunSession` (SwiftData @Model) は Sendable ではないため、HealthKit書き込み用に値型のスナップショットを渡す
struct WorkoutWriteData: Sendable, Equatable {
    let startDate: Date
    let endDate: Date
    let distanceMeters: Double
    let calories: Int?
}

enum HealthKitError: Error, Sendable {
    case notAvailable
    case writeFailed(String)
    case queryFailed(String)
}

protocol HealthKitServiceProtocol: Sendable {
    var isHealthDataAvailable: Bool { get }
    var writeAuthorizationStatus: HealthKitAuthorizationStatus { get }

    func requestAuthorization() async throws
    func refreshAuthorizationStatus()
    func fetchLatestBodyMassKg() async -> Double?
    func fetchHeartRateSummary(start: Date, end: Date) async -> HealthKitHeartRateSummary?
    func writeWorkout(_ workout: WorkoutWriteData, locations: [CLLocation]) async throws
}
