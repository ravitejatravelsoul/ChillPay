import Foundation

/// Represents a short note or remark left by a user on an expense.
struct Comment: Identifiable, Hashable, Codable {
    let id: UUID
    let user: User
    let text: String
    let date: Date
}
