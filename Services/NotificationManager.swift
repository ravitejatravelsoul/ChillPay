import Foundation
import UserNotifications

// Disable printing in release builds by shadowing `print` when not
// compiling with the `DEBUG` flag. This keeps debug logs from shipping to
// production without touching individual log statements.
#if !DEBUG
private func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Call once early (AppDelegate is fine)
    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ Notification permission request error: \(error.localizedDescription)")
                } else {
                    print("✅ Notification permission request result: \(granted)")
                }
            }
        }
    }

    // Only for monthly outstanding reminder (local)
    func scheduleMonthlyOutstandingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Monthly Reminder"
        content.body = "You have outstanding expenses to review in ChillPay!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthlyOutstandingReminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule monthly outstanding reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled monthly outstanding reminder")
            }
        }
    }
}
