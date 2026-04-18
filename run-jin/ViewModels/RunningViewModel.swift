import CoreLocation
import MapKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RunningViewModel {
    let runSessionService: RunSessionService
    let voiceFeedbackService: VoiceFeedbackServiceProtocol
    let runCompletionService: RunCompletionService
    let runSyncService: RunSyncService

    var state: RunSessionState { runSessionService.state }
    var stats: RunStats { runSessionService.currentStats }
    var routeCoordinates: [CLLocationCoordinate2D] { runSessionService.routeCoordinates }

    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: - Territory Reveal

    var showTerritoryReveal = false
    var captureResult: CaptureResult? { runCompletionService.captureResult }
    private(set) var completedSession: RunSession?

    // MARK: - Screen Lock

    var isScreenLocked = false

    /// 最後に音声通知した距離（km単位、切り捨て整数）
    private var lastAnnouncedKilometer = 0

    init(
        runSessionService: RunSessionService,
        voiceFeedbackService: VoiceFeedbackServiceProtocol,
        runCompletionService: RunCompletionService,
        runSyncService: RunSyncService
    ) {
        self.runSessionService = runSessionService
        self.voiceFeedbackService = voiceFeedbackService
        self.runCompletionService = runCompletionService
        self.runSyncService = runSyncService
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

    func finishRun() async {
        unlockScreen()
        guard let session = await runSessionService.finish() else { return }

        completedSession = session
        await runCompletionService.processCompletedRun(session)

        if let result = captureResult,
           !result.capturedCells.isEmpty || !result.overriddenCells.isEmpty {
            showTerritoryReveal = true
        } else {
            // セルなし: リビールをスキップして直接同期
            await submitInBackground(session: session)
        }
    }

    func onRevealDismissed() {
        guard let session = completedSession else { return }
        Task {
            await submitInBackground(session: session)
        }
        runCompletionService.reset()
        completedSession = nil
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

    // MARK: - Private

    private func submitInBackground(session: RunSession) async {
        let cells = runCompletionService.extractedCells
        do {
            _ = try await runSyncService.submitRun(session: session, cells: cells)
        } catch {
            // オフライン時はpendingのまま、次回ネットワーク復帰時にリトライ
        }
    }
}
