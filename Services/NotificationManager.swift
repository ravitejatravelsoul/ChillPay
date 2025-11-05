import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Only for monthly outstanding reminder (local)
    func scheduleMonthlyOutstandingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Monthly Reminder"
        content.body = "You have outstanding expenses to review in ChillPay!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = 1 // 1st day of the month
        dateComponents.hour = 10 // 10am

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthlyOutstandingReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule monthly outstanding reminder: \(error)")
            }
        }
    }

    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // For all push notifications (to other users)
    func sendPushNotification(to user: User, title: String, body: String) {
        guard let url = URL(string: "https://us-central1-chillpay-358ad.cloudfunctions.net/sendPush") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "recipientUserId": user.id,
            "title": title,
            "body": body
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send push notification: \(error)")
            } else {
                print("Push notification sent to \(user.name)")
            }
        }
        task.resume()
    }
}
