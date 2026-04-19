import CoreLocation
import Foundation
import os

final class LocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private let continuation: AsyncStream<CLLocation>.Continuation
    let locationStream: AsyncStream<CLLocation>

    private let _authorizationStatus: OSAllocatedUnfairLock<LocationAuthorizationStatus>

    var authorizationStatus: LocationAuthorizationStatus {
        _authorizationStatus.withLock { $0 }
    }

    /// GPS精度フィルタ: この値より大きいaccuracyの測位は無視
    private let accuracyThreshold: Double = 20.0

    override init() {
        let (stream, continuation) = AsyncStream<CLLocation>.makeStream()
        self.locationStream = stream
        self.continuation = continuation
        self.manager = CLLocationManager()
        self._authorizationStatus = OSAllocatedUnfairLock(initialState: .notDetermined)

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5.0
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .fitness
        manager.showsBackgroundLocationIndicator = true

        updateAuthorizationStatus(manager.authorizationStatus)
    }

    deinit {
        continuation.finish()
    }

    // MARK: - LocationServiceProtocol

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        // allowsBackgroundLocationUpdates は authorization が付与されている時のみ有効化する。
        // notDetermined/denied で true にすると CLLocationManager が警告を出す。
        if manager.authorizationStatus == .authorizedAlways ||
           manager.authorizationStatus == .authorizedWhenInUse {
            manager.allowsBackgroundLocationUpdates = true
        }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            guard location.horizontalAccuracy >= 0,
                  location.horizontalAccuracy <= accuracyThreshold else {
                continue
            }
            continuation.yield(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // GPS取得失敗はログのみ。ストリームは継続
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus(manager.authorizationStatus)
    }

    // MARK: - Private

    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        let mapped: LocationAuthorizationStatus = switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .authorizedWhenInUse
        case .authorizedAlways: .authorizedAlways
        @unknown default: .denied
        }
        _authorizationStatus.withLock { $0 = mapped }
    }
}
