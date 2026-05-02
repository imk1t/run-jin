import CoreLocation
import Foundation
import HealthKit
import os

/// Apple Health (HealthKit) との連携サービス。
///
/// ラン完了時に `HKWorkout` + `HKWorkoutRoute` + カロリー/距離サンプルを
/// Apple Health に保存する。また、カロリー計算精度向上のために体重を読み込む。
///
/// - Important: `HKHealthStore` が `Sendable` 非準拠のため `@unchecked Sendable`。
///   このクラス自体はステートレスで、全ての操作は `async` 境界越しに行う。
final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    private let store = HKHealthStore()
    private let logger = Logger(subsystem: "app.space.k1t.run-jin", category: "HealthKit")

    nonisolated var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Types

    private nonisolated var shareTypes: Set<HKSampleType> {
        [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
        ]
    }

    private nonisolated var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.bodyMass),
        ]
    }

    // MARK: - HealthKitServiceProtocol

    nonisolated var authorizationStatus: HealthKitAuthorizationStatus {
        get async {
            guard HKHealthStore.isHealthDataAvailable() else {
                return .notAvailable
            }
            let status = store.authorizationStatus(for: HKObjectType.workoutType())
            switch status {
            case .notDetermined:
                return .notDetermined
            case .sharingDenied:
                return .sharingDenied
            case .sharingAuthorized:
                return .sharingAuthorized
            @unknown default:
                return .notDetermined
            }
        }
    }

    nonisolated func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            throw HealthKitError.authorizationDenied
        }
    }

    nonisolated func saveWorkout(from data: HealthKitWorkoutData) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let locations: [CLLocation] = data.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map { loc in
                CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: loc.latitude,
                        longitude: loc.longitude
                    ),
                    altitude: loc.altitude,
                    horizontalAccuracy: loc.accuracy,
                    verticalAccuracy: loc.accuracy,
                    course: -1,
                    speed: loc.speed,
                    timestamp: loc.timestamp
                )
            }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        do {
            try await builder.beginCollection(at: data.startedAt)

            if data.distanceMeters > 0 {
                let distanceSample = HKQuantitySample(
                    type: HKQuantityType(.distanceWalkingRunning),
                    quantity: HKQuantity(unit: .meter(), doubleValue: data.distanceMeters),
                    start: data.startedAt,
                    end: data.endedAt
                )
                try await builder.addSamples([distanceSample])
            }

            if data.calories > 0 {
                let calorieSample = HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(data.calories)),
                    start: data.startedAt,
                    end: data.endedAt
                )
                try await builder.addSamples([calorieSample])
            }

            try await builder.endCollection(at: data.endedAt)

            guard let workout = try await builder.finishWorkout() else {
                throw HealthKitError.saveFailed("finishWorkout returned nil")
            }

            if !locations.isEmpty {
                let routeBuilder = HKWorkoutRouteBuilder(healthStore: store, device: .local())
                try await routeBuilder.insertRouteData(locations)
                _ = try await routeBuilder.finishRoute(with: workout, metadata: nil)
            }

            logger.info("HealthKit workout saved: \(data.distanceMeters)m, \(data.calories)kcal")
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("HealthKit workout save failed: \(error.localizedDescription)")
            throw HealthKitError.saveFailed(error.localizedDescription)
        }
    }

    nonisolated func fetchLatestBodyMassKg() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return nil
        }

        let bodyMassType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    self.logger.debug("BodyMass read failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
