import CoreLocation
import Foundation
import SwiftyH3

final class H3Service: H3ServiceProtocol {
    private let resolution: H3Cell.Resolution

    init(resolution: H3Cell.Resolution = .res10) {
        self.resolution = resolution
    }

    func h3Index(for coordinate: CLLocationCoordinate2D) throws -> String {
        let latLng = H3LatLng(coordinate)
        let cell = try latLng.cell(at: resolution)
        return cell.description
    }

    func boundary(for h3Index: String) throws -> [CLLocationCoordinate2D] {
        guard let cell = H3Cell(h3Index) else {
            throw H3ServiceError.invalidIndex(h3Index)
        }
        return try cell.boundary.map { $0.coordinates }
    }

    func h3Indices(for coordinates: [CLLocationCoordinate2D]) throws -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for coordinate in coordinates {
            let index = try h3Index(for: coordinate)
            if seen.insert(index).inserted {
                result.append(index)
            }
        }

        return result
    }

    func kRing(for h3Index: String, distance: Int) throws -> [String] {
        guard let cell = H3Cell(h3Index) else {
            throw H3ServiceError.invalidIndex(h3Index)
        }
        return try cell.gridDisk(distance: Int32(distance)).map { $0.description }
    }
}

enum H3ServiceError: Error, LocalizedError {
    case invalidIndex(String)

    var errorDescription: String? {
        switch self {
        case .invalidIndex(let index):
            "無効なH3インデックス: \(index)"
        }
    }
}
