import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}
