import CoreLocation
import MapKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RunningViewModel {
    let runSessionService: RunSessionService

    var state: RunSessionState { runSessionService.state }
    var stats: RunStats { runSessionService.currentStats }
    var routeCoordinates: [CLLocationCoordinate2D] { runSessionService.routeCoordinates }

    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    init(runSessionService: RunSessionService) {
        self.runSessionService = runSessionService
    }

    func startRun() async {
        await runSessionService.start()
    }

    func pauseRun() {
        runSessionService.pause()
    }

    func resumeRun() async {
        await runSessionService.resume()
    }

    func finishRun() async -> RunSession? {
        await runSessionService.finish()
    }

    var formattedDistance: String {
        let km = stats.distanceMeters / 1000.0
        return String(format: "%.2f", km)
    }

    var formattedDuration: String {
        let minutes = stats.durationSeconds / 60
        let seconds = stats.durationSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedPace: String {
        guard let pace = stats.paceSecondsPerKm else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedCalories: String {
        "\(stats.calories)"
    }
}
