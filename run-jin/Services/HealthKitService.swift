import CoreLocation
import Foundation
import HealthKit
import os

final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "app.space.k1t.run-jin", category: "HealthKitService")

    private let _writeAuthorizationStatus: OSAllocatedUnfairLock<HealthKitAuthorizationStatus>

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var writeAuthorizationStatus: HealthKitAuthorizationStatus {
        _writeAuthorizationStatus.withLock { $0 }
    }

    init() {
        let initial: HealthKitAuthorizationStatus = HKHealthStore.isHealthDataAvailable() ? .notDetermined : .notAvailable
        self._writeAuthorizationStatus = OSAllocatedUnfairLock(initialState: initial)
        if HKHealthStore.isHealthDataAvailable() {
            updateAuthorizationStatusFromStore()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            _writeAuthorizationStatus.withLock { $0 = .notAvailable }
            throw HealthKitError.notAvailable
        }

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
        ]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        updateAuthorizationStatusFromStore()
    }

    func refreshAuthorizationStatus() {
        updateAuthorizationStatusFromStore()
    }

    private func updateAuthorizationStatusFromStore() {
        guard HKHealthStore.isHealthDataAvailable() else {
            _writeAuthorizationStatus.withLock { $0 = .notAvailable }
            return
        }
        let status = healthStore.authorizationStatus(for: HKWorkoutType.workoutType())
        let mapped: HealthKitAuthorizationStatus = switch status {
        case .notDetermined: .notDetermined
        case .sharingDenied: .sharingDenied
        case .sharingAuthorized: .sharingAuthorized
        @unknown default: .notDetermined
        }
        _writeAuthorizationStatus.withLock { $0 = mapped }
    }

    // MARK: - Body Mass

    func fetchLatestBodyMassKg() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let bodyMassType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate

    func fetchHeartRateSummary(start: Date, end: Date) async -> HealthKitHeartRateSummary? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage, .discreteMax]
            ) { _, statistics, _ in
                let avg = statistics?.averageQuantity()?.doubleValue(for: bpmUnit)
                let max = statistics?.maximumQuantity()?.doubleValue(for: bpmUnit)
                guard let avg, let max else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: HealthKitHeartRateSummary(
                    avgBpm: Int(avg.rounded()),
                    maxBpm: Int(max.rounded())
                ))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Workout Write

    func writeWorkout(_ workout: WorkoutWriteData, locations: [CLLocation]) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        do {
            try await builder.beginCollection(at: workout.startDate)

            var samples: [HKSample] = []
            let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: workout.distanceMeters)
            samples.append(HKQuantitySample(
                type: HKQuantityType(.distanceWalkingRunning),
                quantity: distanceQuantity,
                start: workout.startDate,
                end: workout.endDate
            ))

            if let calories = workout.calories, calories > 0 {
                let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
                samples.append(HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: energyQuantity,
                    start: workout.startDate,
                    end: workout.endDate
                ))
            }

            if !samples.isEmpty {
                try await builder.addSamples(samples)
            }

            try await builder.endCollection(at: workout.endDate)
            let finishedWorkout = try await builder.finishWorkout()

            if locations.count >= 2, let finishedWorkout {
                let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
                try await routeBuilder.insertRouteData(locations)
                _ = try await routeBuilder.finishRoute(with: finishedWorkout, metadata: nil)
            }
        } catch {
            logger.error("HealthKit workout write failed: \(error.localizedDescription, privacy: .public)")
            throw HealthKitError.writeFailed(error.localizedDescription)
        }
    }
}
