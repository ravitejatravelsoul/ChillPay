import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let amount: Double
    let paidBy: User
    let participants: [User]
    let date: Date
    let category: ExpenseCategory
    let isRecurring: Bool
    var comments: [Comment]
    var isSettled: Bool = false // <-- Add this line
}
