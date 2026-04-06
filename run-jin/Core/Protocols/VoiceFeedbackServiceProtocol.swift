import Foundation

protocol VoiceFeedbackServiceProtocol: Sendable {
    func announceKilometerPassed(kilometer: Int, paceSecondsPerKm: Double?) async
    func setEnabled(_ enabled: Bool)
}
