import AVFoundation
import Foundation

final class VoiceFeedbackService: VoiceFeedbackServiceProtocol, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private let japaneseVoice = AVSpeechSynthesisVoice(language: "ja-JP")
    private var isEnabled = true

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func announceKilometerPassed(kilometer: Int, paceSecondsPerKm: Double?) async {
        guard isEnabled else { return }

        let message = buildMessage(kilometer: kilometer, paceSecondsPerKm: paceSecondsPerKm)
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = japaneseVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0

        configureAudioSession()
        synthesizer.speak(utterance)
    }

    // MARK: - Private

    private func buildMessage(kilometer: Int, paceSecondsPerKm: Double?) -> String {
        var parts: [String] = []

        parts.append("\(kilometer)キロメートル通過")

        if let pace = paceSecondsPerKm {
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            parts.append("ペース\(minutes)分\(seconds)秒")
        }

        return parts.joined(separator: "、")
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session configuration failed — continue silently
        }
    }
}
