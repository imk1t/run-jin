import CoreLocation
import Testing
@testable import run_jin

struct TerritoryCaptureEngineTests {
    let h3Service = H3Service()
    lazy var engine = TerritoryCaptureEngine(h3Service: h3Service)

    @Test mutating func extractCellsFromRoute() throws {
        // 東京駅付近の直線ルート（約100m）
        let coordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6815, longitude: 139.7675),
            CLLocationCoordinate2D(latitude: 35.6820, longitude: 139.7680),
        ]
        let cells = try engine.extractCells(from: coordinates)
        #expect(cells.count >= 1)
        #expect(cells.allSatisfy { $0.distanceMeters > 0 })
    }

    @Test mutating func captureUnownedCells() throws {
        let cells = [
            CellCaptureData(h3Index: "8a2a1072b59ffff", distanceMeters: 50),
            CellCaptureData(h3Index: "8a2a1072b5bffff", distanceMeters: 30),
        ]
        let result = engine.evaluateCaptures(
            cells: cells,
            currentUserId: "user-1",
            existingTerritories: []
        )
        #expect(result.capturedCells.count == 2)
        #expect(result.overriddenCells.isEmpty)
        #expect(result.failedCells.isEmpty)
    }

    @Test mutating func skipOwnCells() throws {
        let cells = [CellCaptureData(h3Index: "8a2a1072b59ffff", distanceMeters: 50)]
        let existing = [Territory(h3Index: "8a2a1072b59ffff", ownerId: "user-1", totalDistanceMeters: 30)]
        let result = engine.evaluateCaptures(
            cells: cells,
            currentUserId: "user-1",
            existingTerritories: existing
        )
        #expect(result.capturedCells.isEmpty)
        #expect(result.overriddenCells.isEmpty)
        #expect(result.failedCells.isEmpty)
    }

    @Test mutating func overrideWithSufficientDistance() throws {
        let cells = [CellCaptureData(h3Index: "8a2a1072b59ffff", distanceMeters: 100)]
        let existing = [Territory(h3Index: "8a2a1072b59ffff", ownerId: "user-2", totalDistanceMeters: 50)]
        // 100 > 50 × 1.5 = 75 → 上書き成功
        let result = engine.evaluateCaptures(
            cells: cells,
            currentUserId: "user-1",
            existingTerritories: existing
        )
        #expect(result.overriddenCells.count == 1)
        #expect(result.failedCells.isEmpty)
    }

    @Test mutating func failOverrideWithInsufficientDistance() throws {
        let cells = [CellCaptureData(h3Index: "8a2a1072b59ffff", distanceMeters: 60)]
        let existing = [Territory(h3Index: "8a2a1072b59ffff", ownerId: "user-2", totalDistanceMeters: 50)]
        // 60 <= 50 × 1.5 = 75 → 上書き失敗
        let result = engine.evaluateCaptures(
            cells: cells,
            currentUserId: "user-1",
            existingTerritories: existing
        )
        #expect(result.failedCells.count == 1)
        #expect(result.overriddenCells.isEmpty)
    }
}
