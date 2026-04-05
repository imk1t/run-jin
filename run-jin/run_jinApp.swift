import SwiftUI
import SwiftData

@main
struct run_jinApp: App {
    let container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            TabBarView()
        }
    }
}
