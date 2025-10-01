import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: User
    var participants: [User]
    var date: Date
    var groupID: UUID? // nil if direct friend expense
    var comments: [Comment] = []
    var category: ExpenseCategory = .other
    var isRecurring: Bool = false
}
