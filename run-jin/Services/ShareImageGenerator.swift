import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// シェア画像のフォーマット
enum ShareImageFormat: String, CaseIterable, Identifiable {
    case story = "9:16"
    case square = "1:1"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .story: CGSize(width: 1080, height: 1920)
        case .square: CGSize(width: 1080, height: 1080)
        }
    }

    var displayName: String {
        switch self {
        case .story: String(localized: "ストーリー (9:16)")
        case .square: String(localized: "スクエア (1:1)")
        }
    }
}

/// ランニングセッションからSNSシェア用画像を生成するサービス
protocol ShareImageGenerating: Sendable {
    func generateImage(
        session: RunSession,
        format: ShareImageFormat,
        mapSnapshot: UIImage?
    ) async -> UIImage?
}

final class ShareImageGenerator: ShareImageGenerating {

    /// マップスナップショットを取得
    func requestMapSnapshot(
        coordinates: [CLLocationCoordinate2D],
        size: CGSize
    ) async -> UIImage? {
        guard coordinates.count >= 2 else { return nil }

        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else {
            return nil
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.002,
            longitudeDelta: (maxLng - minLng) * 1.5 + 0.002
        )

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: center, span: span)
        options.size = size
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            let image = UIGraphicsImageRenderer(size: size).image { context in
                snapshot.image.draw(at: .zero)

                guard coordinates.count >= 2 else { return }

                let path = UIBezierPath()
                for (index, coord) in coordinates.enumerated() {
                    let point = snapshot.point(for: coord)
                    if index == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }

                context.cgContext.setStrokeColor(UIColor.systemBlue.cgColor)
                context.cgContext.setLineWidth(4)
                context.cgContext.setLineCap(.round)
                context.cgContext.setLineJoin(.round)
                context.cgContext.addPath(path.cgPath)
                context.cgContext.strokePath()
            }
            return image
        } catch {
            return nil
        }
    }

    func generateImage(
        session: RunSession,
        format: ShareImageFormat,
        mapSnapshot: UIImage?
    ) async -> UIImage? {
        let size = format.size
        let renderer = UIGraphicsImageRenderer(size: size)

        let distance = String(format: "%.2f", session.distanceMeters / 1000.0)
        let durationMinutes = session.durationSeconds / 60
        let durationSeconds = session.durationSeconds % 60
        let duration = String(format: "%d:%02d", durationMinutes, durationSeconds)
        let pace: String
        if let avgPace = session.avgPaceSecondsPerKm {
            let paceMin = Int(avgPace) / 60
            let paceSec = Int(avgPace) % 60
            pace = String(format: "%d:%02d", paceMin, paceSec)
        } else {
            pace = "--:--"
        }

        let image = renderer.image { context in
            let ctx = context.cgContext

            // 背景グラデーション
            let colors = [
                UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor,
                UIColor(red: 0.15, green: 0.15, blue: 0.35, alpha: 1.0).cgColor,
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )
            if let gradient {
                ctx.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            }

            // マップスナップショット
            let mapHeight: CGFloat
            switch format {
            case .story: mapHeight = size.height * 0.5
            case .square: mapHeight = size.height * 0.45
            }
            let mapY: CGFloat = 80

            if let mapSnapshot {
                let mapRect = CGRect(x: 40, y: mapY, width: size.width - 80, height: mapHeight)
                let clipPath = UIBezierPath(roundedRect: mapRect, cornerRadius: 20)
                ctx.saveGState()
                clipPath.addClip()
                mapSnapshot.draw(in: mapRect)
                ctx.restoreGState()

                // マップボーダー
                UIColor.white.withAlphaComponent(0.3).setStroke()
                clipPath.lineWidth = 2
                clipPath.stroke()
            }

            // 統計情報エリア
            let statsY = mapY + mapHeight + 40

            drawStats(
                distance: distance,
                duration: duration,
                pace: pace,
                cells: session.cellsCaptured,
                at: CGPoint(x: 40, y: statsY),
                width: size.width - 80
            )

            // アプリロゴウォーターマーク
            let watermarkY = size.height - 80
            drawWatermark(at: CGPoint(x: size.width / 2, y: watermarkY))
        }

        return image
    }

    // MARK: - Private Drawing Helpers

    private func drawStats(
        distance: String,
        duration: String,
        pace: String,
        cells: Int,
        at origin: CGPoint,
        width: CGFloat
    ) {
        let colWidth = width / 2

        drawStatItem(
            title: "距離",
            value: distance,
            unit: "km",
            at: CGPoint(x: origin.x, y: origin.y),
            width: colWidth
        )
        drawStatItem(
            title: "時間",
            value: duration,
            unit: "",
            at: CGPoint(x: origin.x + colWidth, y: origin.y),
            width: colWidth
        )
        drawStatItem(
            title: "ペース",
            value: pace,
            unit: "/km",
            at: CGPoint(x: origin.x, y: origin.y + 120),
            width: colWidth
        )
        drawStatItem(
            title: "陣地",
            value: "\(cells)",
            unit: "セル",
            at: CGPoint(x: origin.x + colWidth, y: origin.y + 120),
            width: colWidth
        )
    }

    private func drawStatItem(
        title: String,
        value: String,
        unit: String,
        at point: CGPoint,
        width: CGFloat
    ) {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .regular)
        let valueFont = UIFont.systemFont(ofSize: 56, weight: .bold)
        let unitFont = UIFont.systemFont(ofSize: 24, weight: .regular)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.white,
        ]
        let unitAttributes: [NSAttributedString.Key: Any] = [
            .font: unitFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
        ]

        let titleString = NSString(string: title)
        let titleSize = titleString.size(withAttributes: titleAttributes)
        let titleX = point.x + (width - titleSize.width) / 2
        titleString.draw(at: CGPoint(x: titleX, y: point.y), withAttributes: titleAttributes)

        let valueString = NSString(string: value)
        let valueSize = valueString.size(withAttributes: valueAttributes)
        let unitString = NSString(string: unit)
        let unitSize = unit.isEmpty ? CGSize.zero : unitString.size(withAttributes: unitAttributes)
        let totalWidth = valueSize.width + (unit.isEmpty ? 0 : unitSize.width + 4)
        let valueX = point.x + (width - totalWidth) / 2

        valueString.draw(
            at: CGPoint(x: valueX, y: point.y + 32),
            withAttributes: valueAttributes
        )

        if !unit.isEmpty {
            unitString.draw(
                at: CGPoint(
                    x: valueX + valueSize.width + 4,
                    y: point.y + 32 + valueSize.height - unitSize.height - 4
                ),
                withAttributes: unitAttributes
            )
        }
    }

    private func drawWatermark(at center: CGPoint) {
        let text = NSString(string: "ラン陣")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
        ]
        let textSize = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2),
            withAttributes: attributes
        )
    }
}
