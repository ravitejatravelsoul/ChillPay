import Foundation

/// Represents a manual adjustment between two users in a group.
/// Adjustments are applied on top of regular expense balances.
struct Adjustment: Identifiable, Hashable, Codable {
    let id: UUID
    let from: User
    let to: User
    let amount: Double
    let date: Date
}
