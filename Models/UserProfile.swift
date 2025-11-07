import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let uid: String
    var name: String                      // <--- make this 'var'
    let email: String
    let providers: [String]
    let emailVerified: Bool
    var avatar: String?                   // <--- var
    let createdAt: Date
    let lastLoginAt: Date
    var bio: String?                      // <--- var
    var phone: String?                    // <--- var
    var notificationsEnabled: Bool        // <--- var
    var faceIDEnabled: Bool               // <--- var
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
        phone: String? = nil,
        notificationsEnabled: Bool = true,
        faceIDEnabled: Bool = false,
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
        self.phone = phone
        self.notificationsEnabled = notificationsEnabled
        self.faceIDEnabled = faceIDEnabled
        self.groups = groups
        self.friends = friends
        self.pushToken = pushToken
        self.settings = settings
        self.deleted = deleted
        self.lastActivityAt = lastActivityAt
        self.platform = platform
    }
}
