import SwiftUI
import SwiftData

@main
struct DaygramApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MemoryEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AuthenticationView()
        }
        .modelContainer(sharedModelContainer)
    }
}