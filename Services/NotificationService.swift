import Foundation

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func sendNotification(to user: User, message: String) {
        // Implement notification logic here (e.g. call APNs).
    }
}
