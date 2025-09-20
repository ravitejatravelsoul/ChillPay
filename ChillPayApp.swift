import SwiftUI

@main
struct ChillPayApp: App {
    init() {
        // Request notification permissions on launch so that reminders can be scheduled later.
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
