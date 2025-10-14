import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String?

    // Only compare by id for equality and hashing
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
