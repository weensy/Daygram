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
    
    init() {
        restoreNotificationSchedule()
    }

    var body: some Scene {
        WindowGroup {
            // TEMPORARILY DISABLED: App Lock feature disabled for initial release
            // AuthenticationView()
            CalendarView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func restoreNotificationSchedule() {
        let enabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        if enabled {
            let hour = UserDefaults.standard.integer(forKey: "reminderHour")
            let minute = UserDefaults.standard.integer(forKey: "reminderMinute")
            NotificationManager.shared.scheduleDailyReminder(
                hour: hour == 0 ? 22 : hour,
                minute: minute
            )
        }
    }
}