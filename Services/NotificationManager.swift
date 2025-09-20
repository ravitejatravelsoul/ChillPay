import Foundation
import UserNotifications

/// Provides a simple wrapper around `UNUserNotificationCenter` to handle
/// requesting notification permissions and scheduling local reminders.
/// This manager is used by `ExpenseDetailView` to remind users of
/// outstanding expenses.  All notifications are one‑off and non‑repeating.
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    /// Request authorization to send notifications if not already granted.
    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
    
    /// Schedule a single local notification at the specified date/time.
    /// - Parameters:
    ///   - title: The title displayed in the notification banner.
    ///   - body: Additional descriptive text.
    ///   - date: The exact date/time at which to fire the notification.
    func scheduleNotification(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // Break the date into components for the calendar trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}