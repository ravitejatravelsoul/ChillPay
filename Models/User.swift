import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    public var email: String?

    public init(id: UUID, name: String, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }
}
