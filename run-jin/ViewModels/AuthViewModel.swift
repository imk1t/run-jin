import Foundation
import Supabase

enum AuthPhase: Sendable {
    case phoneInput
    case otpVerify
    case authenticated
}

@Observable
final class AuthViewModel {
    var phoneNumber: String = ""
    var otpCode: String = ""
    var phase: AuthPhase = .phoneInput
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    /// +81 形式のE.164電話番号を返す
    var formattedPhone: String {
        let digits = phoneNumber.filter(\.isNumber)
        if digits.hasPrefix("0") {
            return "+81" + String(digits.dropFirst())
        }
        return "+81" + digits
    }

    var isPhoneValid: Bool {
        let digits = phoneNumber.filter(\.isNumber)
        // 日本の携帯番号: 090/080/070 → 10-11桁
        return digits.count >= 10 && digits.count <= 11
    }

    var isOTPValid: Bool {
        otpCode.filter(\.isNumber).count == 6
    }

    func sendOTP() async {
        guard isPhoneValid else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signInWithPhone(phone: formattedPhone)
            phase = .otpVerify
        } catch {
            errorMessage = String(localized: "SMSの送信に失敗しました。もう一度お試しください。")
        }
        isLoading = false
    }

    func verifyOTP() async {
        guard isOTPValid else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.verifyOTP(phone: formattedPhone, code: otpCode)
            phase = .authenticated
        } catch {
            errorMessage = String(localized: "認証コードが正しくありません。もう一度お試しください。")
        }
        isLoading = false
    }

    func goBackToPhoneInput() {
        phase = .phoneInput
        otpCode = ""
        errorMessage = nil
    }
}
