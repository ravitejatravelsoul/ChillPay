import Foundation
import SwiftUI

struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String?

    // MARK: - Avatar Metadata
    /// For legacy emoji avatars (rarely used now)
    var avatar: String? = nil

    /// DiceBear seed used to generate unique avatar
    var avatarSeed: String? = nil

    /// DiceBear style: "adventurer", "bottts", "fun-emoji", etc.
    var avatarStyle: String? = nil

    // MARK: - Identity
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Avatar Helpers
    var avatarColor: Color {
        // deterministic color from id + name
        let palette: [Color] = [
            .blue, .green, .orange, .red, .purple,
            .pink, .yellow, .teal
        ]
        let combinedHash = abs((id + name).hashValue)
        return palette[combinedHash % palette.count]
    }

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    // MARK: - Firestore Serialization
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name
        ]
        if let email = email { dict["email"] = email }
        if let avatar = avatar { dict["avatar"] = avatar }
        if let avatarSeed = avatarSeed { dict["avatarSeed"] = avatarSeed }
        if let avatarStyle = avatarStyle { dict["avatarStyle"] = avatarStyle }
        return dict
    }

    static func fromDict(_ dict: [String: Any]) -> User? {
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String
        else { return nil }

        let email = dict["email"] as? String

        return User(
            id: id,
            name: name,
            email: email,
            avatar: dict["avatar"] as? String,
            avatarSeed: dict["avatarSeed"] as? String,
            avatarStyle: dict["avatarStyle"] as? String
        )
    }
}
