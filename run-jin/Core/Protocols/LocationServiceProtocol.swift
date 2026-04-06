import CoreLocation
import Foundation

enum LocationAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways
}

protocol LocationServiceProtocol: Sendable {
    var locationStream: AsyncStream<CLLocation> { get }
    var authorizationStatus: LocationAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdating()
    func stopUpdating()
}
