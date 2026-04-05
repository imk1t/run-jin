import SwiftUI
import SwiftData

@main
struct run_jinApp: App {
    let container = DependencyContainer.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RunSession.self,
            RunLocation.self,
            Territory.self,
            UserProfile.self,
            Team.self,
            Achievement.self,
            PrivacyZone.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabBarView()
        }
        .modelContainer(sharedModelContainer)
    }
}
