import SwiftUI
import FirebaseCore

@main
struct ChillPayApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthFlowCoordinator()
        }
    }
}
