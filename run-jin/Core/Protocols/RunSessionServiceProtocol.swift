import CoreLocation
import Foundation

enum RunSessionState: Sendable, Equatable {
    case idle
    case running
    case paused
    case finished
}

struct RunStats: Sendable, Equatable {
    var distanceMeters: Double = 0
    var durationSeconds: Int = 0
    var paceSecondsPerKm: Double? = nil
    var calories: Int = 0
    var locationCount: Int = 0
}

protocol RunSessionServiceProtocol: Sendable {
    var state: RunSessionState { get }
    var statsStream: AsyncStream<RunStats> { get }

    func start() async
    func pause()
    func resume() async
    func finish() async -> RunSession?
}
