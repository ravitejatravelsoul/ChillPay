import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let uid: String
    var name: String
    let email: String
    let providers: [String]
    let emailVerified: Bool
    var avatar: String?                      // legacy emoji avatar
    var avatarSeed: String                   // DiceBear seed for API
    var avatarStyle: String                  // DiceBear style for API
    let createdAt: Date
    let lastLoginAt: Date
    var bio: String?
    var phone: String?
    var notificationsEnabled: Bool
    var faceIDEnabled: Bool
    let groups: [String]
    let friends: [String]
    let pushToken: String?
    let settings: [String: Bool]
    let deleted: Bool
    let lastActivityAt: Date
    let platform: String

    /// ISO‑3166‑1 alpha‑2 country code (e.g. "US", "IN"). Used to build a locale for currency formatting.
    var countryCode: String?

    /// ISO‑4217 currency code (e.g. "USD", "INR"). Determines the user’s preferred currency.
    var currencyCode: String?

    init(
        uid: String,
        name: String,
        email: String,
        providers: [String] = [],
        emailVerified: Bool = false,
        avatar: String? = nil,
        avatarSeed: String = "defaultseed",
        avatarStyle: String = "adventurer",
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
        platform: String = "iOS",
        countryCode: String? = nil,
        currencyCode: String? = nil
    ) {
        self.id = uid
        self.uid = uid
        self.name = name
        self.email = email
        self.providers = providers
        self.emailVerified = emailVerified
        self.avatar = avatar
        self.avatarSeed = avatarSeed
        self.avatarStyle = avatarStyle
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

        // Persist locale/currency preferences if supplied. These are optional so that
        // legacy user documents continue to decode without crashing. When nil,
        // the app falls back to the device’s locale in `AuthService.decodeUserProfile`.
        self.countryCode = countryCode
        self.currencyCode = currencyCode
    }
}
