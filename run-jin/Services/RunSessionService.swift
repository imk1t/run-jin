import CoreLocation
import Foundation
import SwiftData
import os

@MainActor
@Observable
final class RunSessionService: RunSessionServiceProtocol {
    private let locationService: LocationServiceProtocol
    private let modelContext: ModelContext

    private(set) var state: RunSessionState = .idle
    private(set) var currentStats = RunStats()

    private var session: RunSession?
    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    private var collectedLocations: [CLLocation] = []
    private var locationTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?

    private let statsContinuation: AsyncStream<RunStats>.Continuation
    let statsStream: AsyncStream<RunStats>

    /// カロリー計算用の体重(kg) — 将来ユーザー設定から取得
    private let userWeightKg: Double = 65.0

    /// GPS誤差フィルタ: 速度が低すぎる or 精度が悪い点を除外
    private let minSpeed: Double = 0.5
    private let maxAccuracy: Double = 20.0

    init(locationService: LocationServiceProtocol, modelContext: ModelContext) {
        self.locationService = locationService
        self.modelContext = modelContext
        let (stream, continuation) = AsyncStream<RunStats>.makeStream()
        self.statsStream = stream
        self.statsContinuation = continuation
    }

    // MARK: - RunSessionServiceProtocol

    func start() async {
        guard state == .idle else { return }

        state = .running
        startTime = Date()
        pausedDuration = 0
        collectedLocations = []
        routeCoordinates = []
        currentStats = RunStats()

        session = RunSession(startedAt: startTime!)

        locationService.startUpdating()
        startListeningToLocations()
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        pauseStartTime = Date()
        locationTask?.cancel()
        timerTask?.cancel()
    }

    func resume() async {
        guard state == .paused else { return }
        state = .running
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        startListeningToLocations()
        startTimer()
    }

    func finish() async -> RunSession? {
        guard state == .running || state == .paused else { return nil }

        if state == .paused, let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }

        state = .finished
        locationService.stopUpdating()
        locationTask?.cancel()
        timerTask?.cancel()

        guard let session else { return nil }

        let endTime = Date()
        session.endedAt = endTime
        session.distanceMeters = currentStats.distanceMeters
        session.durationSeconds = currentStats.durationSeconds
        session.avgPaceSecondsPerKm = currentStats.paceSecondsPerKm
        session.calories = currentStats.calories

        for clLocation in collectedLocations {
            let runLocation = RunLocation(
                latitude: clLocation.coordinate.latitude,
                longitude: clLocation.coordinate.longitude,
                altitude: clLocation.altitude,
                timestamp: clLocation.timestamp,
                accuracy: clLocation.horizontalAccuracy,
                speed: clLocation.speed
            )
            session.locations.append(runLocation)
        }

        modelContext.insert(session)
        try? modelContext.save()

        statsContinuation.finish()

        let result = session
        self.session = nil
        state = .idle
        currentStats = RunStats()
        routeCoordinates = []
        collectedLocations = []
        pausedDuration = 0
        startTime = nil

        return result
    }

    // MARK: - Private

    private func startListeningToLocations() {
        locationTask = Task { [weak self] in
            guard let self else { return }
            for await location in locationService.locationStream {
                guard !Task.isCancelled else { break }
                self.processLocation(location)
            }
        }
    }

    private func processLocation(_ location: CLLocation) {
        guard location.horizontalAccuracy <= maxAccuracy,
              location.speed >= minSpeed else {
            return
        }

        if let lastLocation = collectedLocations.last {
            let delta = location.distance(from: lastLocation)
            // 異常な距離（100m以上/更新）を除外
            let timeDelta = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            if timeDelta > 0 && delta / timeDelta < 15.0 { // 15m/s ≈ 54km/h 上限
                currentStats.distanceMeters += delta
            }
        }

        collectedLocations.append(location)
        routeCoordinates.append(location.coordinate)
        currentStats.locationCount = collectedLocations.count
        updateCalories()
        updatePace()
        statsContinuation.yield(currentStats)
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { break }
                self.updateDuration()
            }
        }
    }

    private func updateDuration() {
        guard let startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        currentStats.durationSeconds = max(0, Int(elapsed))
        updatePace()
        statsContinuation.yield(currentStats)
    }

    private func updatePace() {
        guard currentStats.distanceMeters > 0 else {
            currentStats.paceSecondsPerKm = nil
            return
        }
        let km = currentStats.distanceMeters / 1000.0
        currentStats.paceSecondsPerKm = Double(currentStats.durationSeconds) / km
    }

    private func updateCalories() {
        // 簡易MET式: ランニング ~10 METs
        // カロリー = MET × 体重(kg) × 時間(h)
        let hours = Double(currentStats.durationSeconds) / 3600.0
        currentStats.calories = Int(10.0 * userWeightKg * hours)
    }
}
