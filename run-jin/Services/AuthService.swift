import Foundation
import Auth
import Supabase

final class AuthService: AuthServiceProtocol {
    var currentUser: User? {
        get async {
            try? await supabase.auth.session.user
        }
    }

    var authStateStream: AsyncStream<AuthState> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in supabase.auth.authStateChanges {
                    switch event {
                    case .signedIn:
                        if let user = session?.user {
                            continuation.yield(.signedIn(user))
                        }
                    case .signedOut:
                        continuation.yield(.signedOut)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }
}
