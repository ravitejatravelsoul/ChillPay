import Foundation

public struct User: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var email: String?

    public init(id: UUID, name: String, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }
}
