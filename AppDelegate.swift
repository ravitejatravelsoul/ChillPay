import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // ✅ Initialize Firebase first
        FirebaseApp.configure()
        print("🔥 Firebase configured")
        
        // ✅ Set delegates early
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // ✅ Request push permission
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

        // ⚠️ Don’t request FCM token yet (Firebase does it automatically once APNs token is set)
        // You can still log this to see behavior
        Messaging.messaging().token { token, error in
            if let token = token {
                print("🌟 Initial FCM token (pre-APNs): \(token)")
            } else if let error = error {
                print("⚠️ Initial FCM token error (expected first time): \(error.localizedDescription)")
            }
        }
        return true
    }

    // ✅ Called when APNs registration succeeds
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ didRegisterForRemoteNotifications called")
        
        // Convert token to string for logs
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🍏 APNs device token: \(tokenString)")
        
        // Assign to Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Now request FCM token after APNs is set
        Messaging.messaging().token { token, error in
            if let token = token {
                print("🌟 FCM registration token (post-APNs): \(token)")
            } else if let error = error {
                print("❌ FCM token error (post-APNs): \(error.localizedDescription)")
            }
        }
    }

    // ✅ Called when APNs registration fails
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // ✅ Called when Firebase refreshes the FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔁 Refreshed FCM token (callback): \(fcmToken ?? "nil")")
    }

    // ✅ Foreground notification display
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📲 Foreground notification received: \(notification.request.identifier)")
        completionHandler([.alert, .sound, .badge])
    }
}
