import Foundation

/// Placeholder service for dispatching push or local notifications.
///
/// You could implement remote push notifications, SMS messages or in‑app
/// reminders here.  For now the `sendNotification` method does nothing.
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func sendNotification(to user: User, message: String) {
        // Implement notification logic here (e.g. call APNs).
    }
}
