import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String?
}
