import CoreLocation
import Foundation
import Supabase
import SwiftData

@MainActor
@Observable
final class RunCompletionService {
    private let captureEngine: TerritoryCaptureEngineProtocol
    private let modelContext: ModelContext

    private(set) var captureResult: CaptureResult?
    private(set) var extractedCells: [CellCaptureData] = []
    private(set) var isProcessing = false

    init(
        captureEngine: TerritoryCaptureEngineProtocol,
        modelContext: ModelContext
    ) {
        self.captureEngine = captureEngine
        self.modelContext = modelContext
    }

    /// ラン完了後にセル抽出→楽観的評価を実行
    func processCompletedRun(_ session: RunSession) async {
        isProcessing = true
        defer { isProcessing = false }

        let coordinates = session.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        guard coordinates.count >= 2 else {
            captureResult = CaptureResult(capturedCells: [], overriddenCells: [], failedCells: [])
            return
        }

        do {
            let cells = try captureEngine.extractCells(from: coordinates)
            extractedCells = cells

            // オフラインリトライ用にセルデータをセッションに保存
            session.cellsData = try? JSONEncoder().encode(cells)
            try? modelContext.save()
        } catch {
            extractedCells = []
            captureResult = CaptureResult(capturedCells: [], overriddenCells: [], failedCells: [])
            return
        }

        // 楽観的評価: ローカルTerritoryデータと照合
        // 認証エラー時は空文字列で評価（ローカル比較のみに影響）
        let userId = (try? await currentUserId()) ?? ""
        let descriptor = FetchDescriptor<Territory>()
        let existingTerritories = (try? modelContext.fetch(descriptor)) ?? []

        captureResult = captureEngine.evaluateCaptures(
            cells: extractedCells,
            currentUserId: userId,
            existingTerritories: existingTerritories
        )
    }

    /// サーバー確認後にローカルTerritoryモデルを更新
    func saveTerritoriesLocally(ownerId: String) {
        guard let result = captureResult else { return }

        let cellDistanceMap = Dictionary(
            uniqueKeysWithValues: extractedCells.map { ($0.h3Index, $0.distanceMeters) }
        )

        for h3Index in result.capturedCells {
            let territory = Territory(
                h3Index: h3Index,
                ownerId: ownerId,
                totalDistanceMeters: cellDistanceMap[h3Index] ?? 0
            )
            modelContext.insert(territory)
        }

        for h3Index in result.overriddenCells {
            let targetIndex = h3Index
            let descriptor = FetchDescriptor<Territory>(
                predicate: #Predicate { $0.h3Index == targetIndex }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.ownerId = ownerId
                existing.capturedAt = Date()
                existing.totalDistanceMeters = cellDistanceMap[h3Index] ?? 0
            } else {
                let territory = Territory(
                    h3Index: h3Index,
                    ownerId: ownerId,
                    totalDistanceMeters: cellDistanceMap[h3Index] ?? 0
                )
                modelContext.insert(territory)
            }
        }

        try? modelContext.save()
    }

    func reset() {
        captureResult = nil
        extractedCells = []
    }

    // MARK: - Private

    private func currentUserId() async throws -> String {
        let session = try await supabase.auth.session
        return session.user.id.uuidString
    }
}
