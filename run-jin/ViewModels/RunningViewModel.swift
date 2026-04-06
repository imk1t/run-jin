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
        FormatHelpers.distanceKm(meters: stats.distanceMeters)
    }

    var formattedDuration: String {
        FormatHelpers.durationPadded(seconds: stats.durationSeconds)
    }

    var formattedPace: String {
        FormatHelpers.pace(secondsPerKm: stats.paceSecondsPerKm)
    }

    var formattedCalories: String {
        FormatHelpers.calories(stats.calories)
    }
}
