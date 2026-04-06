import CoreLocation
import MapKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RunningViewModel {
    let runSessionService: RunSessionService
    let voiceFeedbackService: VoiceFeedbackServiceProtocol

    var state: RunSessionState { runSessionService.state }
    var stats: RunStats { runSessionService.currentStats }
    var routeCoordinates: [CLLocationCoordinate2D] { runSessionService.routeCoordinates }

    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: - Screen Lock

    var isScreenLocked = false

    /// 最後に音声通知した距離（km単位、切り捨て整数）
    private var lastAnnouncedKilometer = 0

    init(
        runSessionService: RunSessionService,
        voiceFeedbackService: VoiceFeedbackServiceProtocol
    ) {
        self.runSessionService = runSessionService
        self.voiceFeedbackService = voiceFeedbackService
    }

    func startRun() async {
        lastAnnouncedKilometer = 0
        await runSessionService.start()
    }

    func pauseRun() {
        runSessionService.pause()
    }

    func resumeRun() async {
        await runSessionService.resume()
    }

    func finishRun() async -> RunSession? {
        unlockScreen()
        return await runSessionService.finish()
    }

    // MARK: - Screen Lock

    func lockScreen() {
        guard state == .running || state == .paused else { return }
        isScreenLocked = true
    }

    func unlockScreen() {
        isScreenLocked = false
    }

    // MARK: - Voice Feedback

    /// 距離変化のチェック — RunningTabViewのstats監視から呼ばれる
    func checkKilometerMilestone() {
        let currentKm = Int(stats.distanceMeters / 1000.0)
        if currentKm > lastAnnouncedKilometer && currentKm >= 1 {
            lastAnnouncedKilometer = currentKm
            Task {
                await voiceFeedbackService.announceKilometerPassed(
                    kilometer: currentKm,
                    paceSecondsPerKm: stats.paceSecondsPerKm
                )
            }
        }
    }

    // MARK: - Formatted Values

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
