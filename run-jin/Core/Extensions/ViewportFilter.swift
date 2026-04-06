import CoreLocation
import MapKit

/// Filters territory cells to only those visible in the current map viewport,
/// with a configurable buffer zone to preload nearby cells for smooth panning.
///
/// Performance target: render up to 1000 hex overlays at 60fps by culling
/// off-screen cells before generating MapPolygon geometries.
enum ViewportFilter {

    /// Default buffer ratio applied to the visible region dimensions.
    /// 0.2 = 20% extra on each side, effectively loading 140% of the visible area.
    static let defaultBufferRatio: Double = 0.2

    /// Filters an array of items whose position can be expressed as a coordinate,
    /// returning only those within the map region expanded by `bufferRatio`.
    ///
    /// - Parameters:
    ///   - items: The items to filter.
    ///   - region: The currently visible map region.
    ///   - bufferRatio: Extra area around the visible region (fraction of span).
    ///   - coordinate: Closure that extracts a representative coordinate from each item.
    /// - Returns: Items whose representative coordinate falls within the buffered region.
    static func filter<T>(
        _ items: [T],
        in region: MKCoordinateRegion,
        bufferRatio: Double = defaultBufferRatio,
        coordinate: (T) -> CLLocationCoordinate2D
    ) -> [T] {
        let buffered = bufferedRegion(region, ratio: bufferRatio)
        return items.filter { item in
            contains(buffered, coordinate: coordinate(item))
        }
    }

    /// Filters `Territory` models by checking whether the centroid of their H3 cell
    /// falls within the buffered viewport.
    ///
    /// Uses a lightweight centroid lookup via H3ServiceProtocol to avoid computing
    /// full cell boundaries for off-screen cells.
    ///
    /// - Parameters:
    ///   - territories: All locally-stored territory models.
    ///   - region: The currently visible map region.
    ///   - h3Service: Service for resolving H3 index to centroid coordinate.
    ///   - bufferRatio: Extra area around the visible region.
    /// - Returns: Only the territories whose H3 centroid is inside the buffered region.
    static func filterTerritories(
        _ territories: [Territory],
        in region: MKCoordinateRegion,
        using h3Service: H3ServiceProtocol,
        bufferRatio: Double = defaultBufferRatio
    ) -> [Territory] {
        let buffered = bufferedRegion(region, ratio: bufferRatio)
        return territories.filter { territory in
            guard let centroid = try? h3Service.centroid(for: territory.h3Index) else {
                return false
            }
            return contains(buffered, coordinate: centroid)
        }
    }

    // MARK: - Private Helpers

    /// Expands a map region by the given ratio on each side.
    private static func bufferedRegion(
        _ region: MKCoordinateRegion,
        ratio: Double
    ) -> MKCoordinateRegion {
        let latBuffer = region.span.latitudeDelta * ratio
        let lonBuffer = region.span.longitudeDelta * ratio
        return MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta + latBuffer * 2,
                longitudeDelta: region.span.longitudeDelta + lonBuffer * 2
            )
        )
    }

    /// Checks whether a coordinate falls inside a region's bounding box.
    private static func contains(
        _ region: MKCoordinateRegion,
        coordinate: CLLocationCoordinate2D
    ) -> Bool {
        let halfLat = region.span.latitudeDelta / 2
        let halfLon = region.span.longitudeDelta / 2

        let minLat = region.center.latitude - halfLat
        let maxLat = region.center.latitude + halfLat
        let minLon = region.center.longitude - halfLon
        let maxLon = region.center.longitude + halfLon

        return coordinate.latitude >= minLat
            && coordinate.latitude <= maxLat
            && coordinate.longitude >= minLon
            && coordinate.longitude <= maxLon
    }
}
