import SwiftUI

@main
struct ChillPayApp: App {
    // Attach your custom AppDelegate for notifications and Firebase Messaging
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AuthFlowCoordinator()
        }
    }
}
