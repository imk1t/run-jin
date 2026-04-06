import SwiftUI
import SwiftData
import FirebaseCore

@main
struct run_jinApp: App {
    let container = DependencyContainer.shared

    init() {
        // Only configure Firebase if GoogleService-Info.plist exists (it is gitignored)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

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
