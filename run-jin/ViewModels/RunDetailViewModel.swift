import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
@Observable
final class RunDetailViewModel {
    let session: RunSession

    var routeCoordinates: [CLLocationCoordinate2D] {
        session.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    var mapCameraPosition: MapCameraPosition {
        guard let first = routeCoordinates.first else {
            return .automatic
        }
        if routeCoordinates.count == 1 {
            return .region(MKCoordinateRegion(
                center: first,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            ))
        }
        let lats = routeCoordinates.map(\.latitude)
        let lngs = routeCoordinates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (lats.max()! - lats.min()!) * 1.3 + 0.002,
            longitudeDelta: (lngs.max()! - lngs.min()!) * 1.3 + 0.002
        )
        return .region(MKCoordinateRegion(center: center, span: span))
    }

    /// 1kmスプリット
    var splits: [SplitData] {
        let locations = session.locations
            .sorted { $0.timestamp < $1.timestamp }
        guard locations.count >= 2 else { return [] }

        var result: [SplitData] = []
        var splitDistance: Double = 0
        var splitStartTime = locations[0].timestamp

        for i in 1..<locations.count {
            let prev = CLLocation(latitude: locations[i-1].latitude, longitude: locations[i-1].longitude)
            let curr = CLLocation(latitude: locations[i].latitude, longitude: locations[i].longitude)
            splitDistance += curr.distance(from: prev)

            if splitDistance >= 1000 {
                let splitTime = locations[i].timestamp.timeIntervalSince(splitStartTime)
                let paceSecondsPerKm = splitTime / (splitDistance / 1000.0)
                result.append(SplitData(
                    km: result.count + 1,
                    paceSecondsPerKm: paceSecondsPerKm
                ))
                splitDistance -= 1000
                splitStartTime = locations[i].timestamp
            }
        }

        // 最後の不完全スプリット
        if splitDistance > 100 {
            let splitTime = locations.last!.timestamp.timeIntervalSince(splitStartTime)
            let paceSecondsPerKm = splitTime / (splitDistance / 1000.0)
            result.append(SplitData(
                km: result.count + 1,
                paceSecondsPerKm: paceSecondsPerKm,
                isPartial: true,
                partialMeters: splitDistance
            ))
        }

        return result
    }

    var formattedDistance: String {
        FormatHelpers.distanceKm(meters: session.distanceMeters)
    }

    var formattedDuration: String {
        FormatHelpers.duration(seconds: session.durationSeconds)
    }

    var formattedPace: String {
        FormatHelpers.pace(secondsPerKm: session.avgPaceSecondsPerKm)
    }

    var formattedCalories: String {
        FormatHelpers.calories(session.calories)
    }

    init(session: RunSession) {
        self.session = session
    }
}

struct SplitData: Identifiable {
    let id = UUID()
    let km: Int
    let paceSecondsPerKm: Double
    var isPartial: Bool = false
    var partialMeters: Double = 0

    var formattedPace: String {
        FormatHelpers.pace(secondsPerKm: paceSecondsPerKm)
    }

    var label: String {
        FormatHelpers.splitLabel(km: km, isPartial: isPartial, partialMeters: partialMeters)
    }
}
