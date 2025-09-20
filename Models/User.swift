import Foundation

/// Represents a single person who can belong to a group and participate in expenses.
///
/// Each user has a stable identifier and a display name.  The identifier
/// allows us to track the same person across groups and expenses even if
/// their name changes.
struct User: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}
