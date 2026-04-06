import UIKit

/// Lightweight wrapper around UIImpactFeedbackGenerator for territory reveal haptics.
///
/// Usage:
/// ```swift
/// HapticFeedback.play(.medium)
/// ```
enum HapticFeedback {
    case light
    case medium
    case heavy
    case soft
    case rigid

    /// Fire a single haptic impulse on the main thread.
    @MainActor
    static func play(_ style: HapticFeedback = .medium) {
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle = switch style {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Fire a success / warning / error notification haptic.
    @MainActor
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Play a sequence of light haptics with a given interval, suitable for
    /// the hex-reveal animation where each cell triggers a tap.
    @MainActor
    static func playRevealSequence(count: Int, interval: TimeInterval = 0.08) async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        for i in 0..<count {
            generator.impactOccurred()
            if i < count - 1 {
                try? await Task.sleep(for: .seconds(interval))
            }
        }
        // Finish with a satisfying notification
        notify(.success)
    }
}
