import Foundation

/// A generic event in a group’s lifecycle, used to build an activity feed.
struct Activity: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let date: Date
}
