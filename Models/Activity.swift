import Foundation

struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let date: Date
}
