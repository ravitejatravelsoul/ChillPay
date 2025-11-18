import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()
        print("🔥 Firebase configured")

        // CHECK ENTITLEMENTS ON LAUNCH
        if let entitlements = Bundle.main.entitlementsDictionary {
            print("📦 Loaded App Entitlements: \(entitlements)")
        } else {
            print("⚠️ Could NOT load entitlements! APNs will NOT work.")
        }

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Ask notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            print("📩 Notification permission granted: \(granted)")
            if let error = error { print("❌ Notification permission error: \(error)") }

            guard granted else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                print("📱 Registered for APNs")
            }
        }

        // Try to get FCM token before APNs arrives (normal if failed)
        Messaging.messaging().token { token, error in
            if let token = token {
                print("🌟 Initial FCM token (pre-APNs): \(token)")
            } else if let error = error {
                print("⚠️ Initial FCM token error (expected): \(error.localizedDescription)")
            }
        }

        return true
    }

    // MARK: - Got APNs token
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        print("✅ didRegisterForRemoteNotifications called!")

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🍏 APNs device token: \(tokenString)")

        // IMPORTANT
        Messaging.messaging().apnsToken = deviceToken

        // Retrieve new FCM token now that APNs is linked
        Messaging.messaging().token { token, error in
            if let token = token {
                print("🌟 FCM registration token (post-APNs): \(token)")
            } else if let error = error {
                print("❌ FCM token error (post-APNs): \(error.localizedDescription)")
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Token refreshed callback
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔁 Refreshed FCM token (callback): \(fcmToken ?? "nil")")
    }

    // Foreground notification banner
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📲 Foreground notification: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }
}
extension Bundle {
    var entitlementsDictionary: [String: Any]? {
        guard
            let url = url(forResource: "embedded", withExtension: "entitlements"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        else { return nil }

        return plist as? [String : Any]
    }
}
