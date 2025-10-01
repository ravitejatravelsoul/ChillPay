import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String?
}
