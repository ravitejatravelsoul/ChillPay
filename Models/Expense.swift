import Foundation

/// Represents a single expense shared among a subset of group members.
/// Each expense records the person who paid, the participants who should
/// share the cost and the total amount.
struct Expense: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: User
    var participants: [User]
    var date: Date
    var category: ExpenseCategory
    var isRecurring: Bool
    var comments: [Comment]
}
