import CoreLocation
import Foundation
import SwiftUI

@MainActor
@Observable
final class TerritoryRevealViewModel {
    private let h3Service: H3ServiceProtocol
    private let capturedCells: [String]
    private let overriddenCells: [String]

    // MARK: - Animation State

    private(set) var revealedOverlays: [RevealOverlay] = []
    private(set) var isAnimating = false
    private(set) var isComplete = false

    // MARK: - Summary

    var newCaptureCount: Int { capturedCells.count }
    var overrideCount: Int { overriddenCells.count }

    // MARK: - Private

    private var animationTask: Task<Void, Never>?
    private let delaySeconds: Double

    init(
        captureResult: CaptureResult,
        h3Service: H3ServiceProtocol,
        delaySeconds: Double = 0.1
    ) {
        self.capturedCells = captureResult.capturedCells
        self.overriddenCells = captureResult.overriddenCells
        self.h3Service = h3Service
        self.delaySeconds = delaySeconds
    }

    /// アニメーション開始
    func startReveal() {
        guard !isAnimating, !isComplete else { return }
        isAnimating = true

        let allCells = buildOrderedCells()

        animationTask = Task { [weak self] in
            for cell in allCells {
                guard let self, !Task.isCancelled else { return }
                guard let boundary = try? h3Service.boundary(for: cell.h3Index) else {
                    continue
                }
                let overlay = RevealOverlay(
                    h3Index: cell.h3Index,
                    coordinates: boundary,
                    type: cell.type
                )
                withAnimation(.easeIn(duration: 0.3)) {
                    self.revealedOverlays.append(overlay)
                }
                try? await Task.sleep(for: .milliseconds(Int(delaySeconds * 1000)))
            }
            guard let self, !Task.isCancelled else { return }
            self.isAnimating = false
            self.isComplete = true
        }
    }

    /// アニメーションをスキップして全セルを即座に表示
    func skip() {
        animationTask?.cancel()
        animationTask = nil
        isAnimating = false

        let allCells = buildOrderedCells()
        revealedOverlays = allCells.compactMap { cell in
            guard let boundary = try? h3Service.boundary(for: cell.h3Index) else {
                return nil
            }
            return RevealOverlay(
                h3Index: cell.h3Index,
                coordinates: boundary,
                type: cell.type
            )
        }
        isComplete = true
    }

    func cleanup() {
        animationTask?.cancel()
        animationTask = nil
    }

    // MARK: - Private Helpers

    private func buildOrderedCells() -> [OrderedCell] {
        var cells: [OrderedCell] = []
        let overriddenSet = Set(overriddenCells)

        // 新規獲得セルを先に追加（ルート順を維持）
        for h3Index in capturedCells {
            cells.append(OrderedCell(h3Index: h3Index, type: .captured))
        }
        // 上書きセルを後に追加
        for h3Index in overriddenCells where !overriddenSet.isEmpty {
            cells.append(OrderedCell(h3Index: h3Index, type: .overridden))
        }
        return cells
    }
}

// MARK: - Supporting Types

enum RevealCellType {
    case captured   // 新規獲得 = 青
    case overridden // 上書き = オレンジ
}

struct RevealOverlay: Identifiable {
    let id: String
    let coordinates: [CLLocationCoordinate2D]
    let type: RevealCellType

    init(h3Index: String, coordinates: [CLLocationCoordinate2D], type: RevealCellType) {
        self.id = h3Index
        self.coordinates = coordinates
        self.type = type
    }
}

private struct OrderedCell {
    let h3Index: String
    let type: RevealCellType
}
