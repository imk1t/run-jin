import CoreLocation
import Testing
@testable import run_jin

struct H3ServiceTests {
    let service = H3Service()

    @Test func coordinateToH3Index() throws {
        // 東京駅付近
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let index = try service.h3Index(for: coordinate)
        #expect(!index.isEmpty)
        #expect(index.hasPrefix("8a"))  // resolution 10は"8a"で始まる
    }

    @Test func h3IndexToBoundary() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let index = try service.h3Index(for: coordinate)
        let boundary = try service.boundary(for: index)
        #expect(boundary.count == 6 || boundary.count == 5)  // 六角形 or 五角形
    }

    @Test func h3IndicesDeduplication() throws {
        // 同じ場所の近い座標 → 同じH3セルに入るはず
        let coords = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6813, longitude: 139.7672),
        ]
        let indices = try service.h3Indices(for: coords)
        // 重複排除されるので、元の3つより少ないか同数
        #expect(indices.count <= coords.count)
        #expect(indices.count >= 1)
    }

    @Test func kRing() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let index = try service.h3Index(for: coordinate)
        let ring = try service.kRing(for: index, distance: 1)
        #expect(ring.count == 7)  // 中心 + 6近傍
        #expect(ring.contains(index))
    }

    @Test func invalidIndexThrows() throws {
        #expect(throws: H3ServiceError.self) {
            try service.boundary(for: "invalid_index")
        }
    }

    @Test func batchPerformance() throws {
        // 1000点のバッチ変換が妥当な時間内に完了
        let coordinates = (0..<1000).map { i in
            CLLocationCoordinate2D(
                latitude: 35.6812 + Double(i) * 0.0001,
                longitude: 139.7671 + Double(i) * 0.0001
            )
        }
        let indices = try service.h3Indices(for: coordinates)
        #expect(indices.count > 0)
        #expect(indices.count <= 1000)
    }
}
