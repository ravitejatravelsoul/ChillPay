import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        FirebaseApp.configure()
        print("🔥 Firebase configured")

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("📩 Notification permission granted: \(granted)")
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            guard granted else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                print("📱 Requested to register for remote notifications")
            }
        }

        Messaging.messaging().token { token, error in
            if let token = token {
                print("🌟 Initial FCM token (pre-APNs): \(token)")
            } else if let error = error {
                print("⚠️ Initial FCM token error (expected first time): \(error.localizedDescription)")
            }
        }
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ didRegisterForRemoteNotifications called")
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🍏 APNs device token: \(tokenString)")
        Messaging.messaging().apnsToken = deviceToken

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

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔁 Refreshed FCM token (callback): \(fcmToken ?? "nil")")
    }

    // Foreground notification display
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📲 Foreground notification received: \(notification.request.identifier)")
        // ⚠️ 'alert' is deprecated, but this is expected and required for foreground presentation.
        // Apple provides no replacement, safe to ignore.
        completionHandler([.banner, .sound, .badge]) // Use .banner (iOS 14+) instead of .alert
    }
}
