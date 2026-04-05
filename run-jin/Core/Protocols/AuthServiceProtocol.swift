import Foundation
import Auth

enum AuthState: Sendable {
    case signedOut
    case signedIn(User)
}

protocol AuthServiceProtocol: Sendable {
    var currentUser: User? { get async }
    var authStateStream: AsyncStream<AuthState> { get }

    func signInWithPhone(phone: String) async throws
    func verifyOTP(phone: String, code: String) async throws
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async throws
}
