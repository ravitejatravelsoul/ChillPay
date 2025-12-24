import SwiftUI

// Silence print statements in release builds by shadowing the global `print` function
// when the `DEBUG` flag is not set. This ensures debug logs do not ship with
// the production binary.
#if !DEBUG
private func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

@main
struct ChillPayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AuthFlowCoordinator()
                .environmentObject(CurrencyManager.shared)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        print("🟦 ScenePhase active — forcing APNs register")
                        UIApplication.shared.registerForRemoteNotifications()
                        print("🟦 isRegisteredForRemoteNotifications = \(UIApplication.shared.isRegisteredForRemoteNotifications)")
                    }
                }
        }
    }
}
