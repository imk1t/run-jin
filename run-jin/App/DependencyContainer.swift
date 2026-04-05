import SwiftUI

@Observable
final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    private init() {}
}
