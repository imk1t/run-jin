import CoreLocation
import Foundation

final class TerritoryCaptureEngine: TerritoryCaptureEngineProtocol {
    private let h3Service: H3ServiceProtocol

    /// 上書き閾値: 新しいランナーの距離が既存の距離 × この倍率を超えると上書き
    static let overrideMultiplier: Double = 1.5

    init(h3Service: H3ServiceProtocol) {
        self.h3Service = h3Service
    }

    func extractCells(from coordinates: [CLLocationCoordinate2D]) throws -> [CellCaptureData] {
        guard coordinates.count >= 2 else { return [] }

        var cellDistances: [String: Double] = [:]

        for i in 1..<coordinates.count {
            let prevCoord = coordinates[i - 1]
            let currCoord = coordinates[i]

            let prevIndex = try h3Service.h3Index(for: prevCoord)
            let currIndex = try h3Service.h3Index(for: currCoord)

            let distance = CLLocation(
                latitude: prevCoord.latitude, longitude: prevCoord.longitude
            ).distance(from: CLLocation(
                latitude: currCoord.latitude, longitude: currCoord.longitude
            ))

            // セグメントの距離を両端のセルに半分ずつ配分
            cellDistances[prevIndex, default: 0] += distance / 2
            cellDistances[currIndex, default: 0] += distance / 2
        }

        return cellDistances.map { CellCaptureData(h3Index: $0.key, distanceMeters: $0.value) }
    }

    func evaluateCaptures(
        cells: [CellCaptureData],
        currentUserId: String,
        existingTerritories: [Territory]
    ) -> CaptureResult {
        let territoryMap = Dictionary(
            uniqueKeysWithValues: existingTerritories.map { ($0.h3Index, $0) }
        )

        var captured: [String] = []
        var overridden: [String] = []
        var failed: [String] = []

        for cell in cells {
            if let existing = territoryMap[cell.h3Index] {
                // 自分のセルはスキップ
                if existing.ownerId == currentUserId {
                    continue
                }

                // 上書き判定: 新距離 > 既存距離 × 1.5
                if cell.distanceMeters > existing.totalDistanceMeters * Self.overrideMultiplier {
                    overridden.append(cell.h3Index)
                } else {
                    failed.append(cell.h3Index)
                }
            } else {
                // 未所有セル → 即獲得
                captured.append(cell.h3Index)
            }
        }

        return CaptureResult(
            capturedCells: captured,
            overriddenCells: overridden,
            failedCells: failed
        )
    }
}
