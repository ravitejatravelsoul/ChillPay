import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    var name: String
    var email: String
    var providers: [String]
    var emailVerified: Bool
    var avatar: String? // Emoji
    var createdAt: Date
    var lastLoginAt: Date
    var bio: String?
    var groups: [String]
    var friends: [String]
    var pushToken: String?
    var settings: [String: Bool]
    var deleted: Bool
    var lastActivityAt: Date
    var platform: String
}
