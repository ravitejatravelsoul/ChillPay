import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String?

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Firestore serialization
    func toDict() -> [String: Any] {
        [
            "id": id,
            "name": name,
            "email": email as Any
        ]
    }
    static func fromDict(_ dict: [String: Any]) -> User? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String
        else { return nil }
        let email = dict["email"] as? String
        return User(id: id, name: name, email: email)
    }
}
