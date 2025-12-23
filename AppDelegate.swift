import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

class AppDelegate: NSObject,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate {

    // Cache token until user is logged in
    private var pendingFCMToken: String?
    private var lastSavedToken: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()
        print("🔥 Firebase configured")

        // Delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Ask for permission + APNs
        requestNotificationPermissionAndRegister()

        // Save token after auth becomes available
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                print("✅ Auth ready for uid=\(user.uid)")
                if let token = self.pendingFCMToken {
                    print("📌 Saving pending FCM token after login: \(token)")
                    self.saveFCMTokenToFirestore(token)
                    self.pendingFCMToken = nil
                }
            } else {
                print("⚠️ Auth not ready (logged out). Token will be saved after login.")
            }
        }

        return true
    }

    // MARK: - Notification permission + APNs registration
    private func requestNotificationPermissionAndRegister() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Notification settings (before prompt): auth=\(settings.authorizationStatus.rawValue), alert=\(settings.alertSetting.rawValue), sound=\(settings.soundSetting.rawValue), badge=\(settings.badgeSetting.rawValue)")
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("📩 Notification permission granted: \(granted)")
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("🔔 Notification settings (after prompt): auth=\(settings.authorizationStatus.rawValue), alert=\(settings.alertSetting.rawValue), sound=\(settings.soundSetting.rawValue), badge=\(settings.badgeSetting.rawValue)")
            }

            guard granted else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                print("📱 registerForRemoteNotifications() called")
            }
        }
    }

    // MARK: - APNs SUCCESS
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        print("🟩🟩🟩 APNs SUCCESS CALLBACK HIT 🟩🟩🟩")

        let apnsTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🍏 APNs device token: \(apnsTokenString)")

        // Tell Firebase Messaging about the APNs token
        Messaging.messaging().apnsToken = deviceToken

        // Fetch FCM token AFTER APNs token is set
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ FCM token error (post-APNs): \(error.localizedDescription)")
                return
            }
            guard let token = token else {
                print("❌ FCM token is nil (post-APNs)")
                return
            }

            print("🌟 FCM token (post-APNs): \(token)")
            self?.handleToken(token)
        }
    }

    // MARK: - APNs FAIL
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("🟥🟥🟥 APNs FAIL CALLBACK HIT 🟥🟥🟥 \(error.localizedDescription)")
    }

    // MARK: - FCM token refreshed/updated
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("🔁 didReceiveRegistrationToken: nil")
            return
        }

        print("🔁 Refreshed FCM token (callback): \(token)")
        handleToken(token)
    }

    private func handleToken(_ token: String) {
        if lastSavedToken == token {
            print("ℹ️ Same token already handled in this session -> skip save")
            return
        }
        lastSavedToken = token

        guard Auth.auth().currentUser != nil else {
            print("⚠️ No logged-in user yet. Caching token to save after login.")
            pendingFCMToken = token
            return
        }

        saveFCMTokenToFirestore(token)
    }

    // MARK: - Save token for MULTI-DEVICE support
    private func saveFCMTokenToFirestore(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ No logged-in user. Skipping FCM token save.")
            pendingFCMToken = token
            return
        }

        let db = Firestore.firestore()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        let deviceName = UIDevice.current.name

        let data: [String: Any] = [
            "token": token,
            "platform": "iOS",
            "deviceId": deviceId,
            "deviceName": deviceName,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(uid)
            .collection("pushTokens")
            .document(token)
            .setData(data, merge: true) { error in
                if let error = error {
                    print("❌ Failed saving FCM token: \(error.localizedDescription)")
                } else {
                    print("✅ Saved FCM token to Firestore (multi-device): \(token)")
                }
            }
    }

    // MARK: - Foreground notifications (show banner while app is open)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📲 Foreground notification: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Background / tap handling debug
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 didReceiveRemoteNotification userInfo = \(userInfo)")
        completionHandler(.noData)
    }
}
