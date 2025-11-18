import SwiftUI
import Firebase

@main
struct ChillPayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AuthFlowCoordinator()
        }
    }
}
