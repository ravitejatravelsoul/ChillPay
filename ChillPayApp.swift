import SwiftUI

@main
struct ChillPayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AuthFlowCoordinator()
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
