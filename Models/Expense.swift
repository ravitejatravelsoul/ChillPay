import Foundation

struct Expense: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: ChillPay.User
    var participants: [ChillPay.User]
    var date: Date
    var category: ExpenseCategory
    var isRecurring: Bool
    var comments: [Comment]
    var isSettled: Bool = false
}
