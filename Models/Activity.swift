import Foundation

struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var date: Date
}
