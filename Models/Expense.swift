import Foundation

struct Expense: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: User
    var participants: [User]
    var date: Date
}
