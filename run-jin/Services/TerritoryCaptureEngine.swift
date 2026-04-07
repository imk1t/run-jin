import CoreLocation
import Foundation

final class TerritoryCaptureEngine: TerritoryCaptureEngineProtocol {
    private let h3Service: H3ServiceProtocol

    /// 上書き閾値: 新しいランナーの距離が既存の距離 × この倍率を超えると上書き
    static let overrideMultiplier: Double = 1.5

    init(h3Service: H3ServiceProtocol) {
        self.h3Service = h3Service
    }

    /// 区間を細分化する際のサンプリング間隔（メートル）。
    /// H3 res10 のセル平均エッジ長は約65m。20m 間隔なら線が貫通する全セルを必ず拾える。
    static let segmentSamplingMeters: Double = 20.0

    func extractCells(from coordinates: [CLLocationCoordinate2D]) throws -> [CellCaptureData] {
        guard coordinates.count >= 2 else { return [] }

        var cellDistances: [String: Double] = [:]

        for i in 1..<coordinates.count {
            let prevCoord = coordinates[i - 1]
            let currCoord = coordinates[i]

            let segmentDistance = CLLocation(
                latitude: prevCoord.latitude, longitude: prevCoord.longitude
            ).distance(from: CLLocation(
                latitude: currCoord.latitude, longitude: currCoord.longitude
            ))

            guard segmentDistance > 0 else { continue }

            // 実走行ライン上を貫通する全てのH3セルを拾うため、区間を細分化する
            let steps = max(1, Int(ceil(segmentDistance / Self.segmentSamplingMeters)))
            let subDistance = segmentDistance / Double(steps)

            // 区間始点のセルから走査開始
            var currentIndex = try h3Service.h3Index(for: prevCoord)
            var accumulated = 0.0

            for step in 1...steps {
                let t = Double(step) / Double(steps)
                let lat = prevCoord.latitude + (currCoord.latitude - prevCoord.latitude) * t
                let lon = prevCoord.longitude + (currCoord.longitude - prevCoord.longitude) * t
                let sampleIndex = try h3Service.h3Index(
                    for: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                )

                accumulated += subDistance

                if sampleIndex != currentIndex {
                    // セルが切り替わったタイミングで現セルへ累積距離を加算
                    cellDistances[currentIndex, default: 0] += accumulated
                    currentIndex = sampleIndex
                    accumulated = 0
                }
            }

            // 区間終端の残りを最後のセルに加算
            if accumulated > 0 {
                cellDistances[currentIndex, default: 0] += accumulated
            }
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
