import SwiftUI
import UIKit
import Photos

/// Captures a SwiftUI view as an image and optionally saves it to the photo library.
enum ScreenshotHelper {

    // MARK: - Errors

    enum ScreenshotError: LocalizedError {
        case windowNotFound
        case renderFailed
        case photoLibraryDenied

        var errorDescription: String? {
            switch self {
            case .windowNotFound:
                return String(localized: "画面の取得に失敗しました")
            case .renderFailed:
                return String(localized: "スクリーンショットの作成に失敗しました")
            case .photoLibraryDenied:
                return String(localized: "写真ライブラリへのアクセスが許可されていません")
            }
        }
    }

    // MARK: - Render from SwiftUI View

    /// Render an arbitrary SwiftUI view to a `UIImage`.
    @MainActor
    static func render<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        return image
    }

    // MARK: - Capture current screen

    /// Capture the key window's current content as a `UIImage`.
    @MainActor
    static func captureKeyWindow() throws -> UIImage {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else {
            throw ScreenshotError.windowNotFound
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        return image
    }

    // MARK: - Save to Photos

    /// Save a `UIImage` to the user's photo library.
    /// Requests permission if not yet determined.
    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ScreenshotError.photoLibraryDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }
    }

    // MARK: - Convenience

    /// Capture the current screen and save it to Photos in one step.
    @MainActor
    static func captureAndSave() async throws {
        let image = try captureKeyWindow()
        try await saveToPhotos(image)
    }
}
