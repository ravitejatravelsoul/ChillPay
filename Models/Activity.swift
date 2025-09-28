import Foundation

struct Activity: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let date: Date
}
