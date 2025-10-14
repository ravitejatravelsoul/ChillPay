import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let uid: String
    let name: String
    let email: String
    let providers: [String]
    let emailVerified: Bool
    var avatar: String?
    let createdAt: Date
    let lastLoginAt: Date
    let bio: String?
    let groups: [String]
    let friends: [String]
    let pushToken: String?
    let settings: [String: Bool]
    let deleted: Bool
    let lastActivityAt: Date
    let platform: String

    init(
        uid: String,
        name: String,
        email: String,
        providers: [String] = [],
        emailVerified: Bool = false,
        avatar: String? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        bio: String? = nil,
        groups: [String] = [],
        friends: [String] = [],
        pushToken: String? = nil,
        settings: [String: Bool] = [:],
        deleted: Bool = false,
        lastActivityAt: Date = Date(),
        platform: String = "iOS"
    ) {
        self.id = uid
        self.uid = uid
        self.name = name
        self.email = email
        self.providers = providers
        self.emailVerified = emailVerified
        self.avatar = avatar
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.bio = bio
        self.groups = groups
        self.friends = friends
        self.pushToken = pushToken
        self.settings = settings
        self.deleted = deleted
        self.lastActivityAt = lastActivityAt
        self.platform = platform
    }
}
