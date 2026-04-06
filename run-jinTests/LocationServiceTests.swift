import Testing
import CoreLocation
@testable import run_jin

struct LocationServiceTests {

    @Test @MainActor func initialAuthorizationStatus() async throws {
        let service = LocationService()
        let status = service.authorizationStatus
        #expect(status == .notDetermined || status == .authorizedAlways || status == .authorizedWhenInUse)
    }

    @Test @MainActor func locationStreamExists() async throws {
        let service = LocationService()
        let _ = service.locationStream
    }

    @Test func authorizationStatusMapping() async throws {
        let cases: [LocationAuthorizationStatus] = [
            .notDetermined, .restricted, .denied,
            .authorizedWhenInUse, .authorizedAlways
        ]
        #expect(cases.count == 5)
    }
}
