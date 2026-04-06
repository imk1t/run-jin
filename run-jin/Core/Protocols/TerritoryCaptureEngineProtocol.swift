import CoreLocation
import Foundation

struct CaptureResult: Sendable {
    let capturedCells: [String]   // 新規獲得したH3インデックス
    let overriddenCells: [String] // 上書きしたH3インデックス
    let failedCells: [String]     // 上書き条件を満たさなかったH3インデックス
}

struct CellCaptureData: Sendable {
    let h3Index: String
    let distanceMeters: Double
}

protocol TerritoryCaptureEngineProtocol: Sendable {
    /// GPS座標列からH3セルリストを生成し、各セルの通過距離を計算
    func extractCells(from coordinates: [CLLocationCoordinate2D]) throws -> [CellCaptureData]

    /// ローカルのTerritoryデータに基づく獲得/上書き判定（楽観的）
    func evaluateCaptures(
        cells: [CellCaptureData],
        currentUserId: String,
        existingTerritories: [Territory]
    ) -> CaptureResult
}
