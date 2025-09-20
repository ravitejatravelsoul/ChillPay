import Foundation

struct Group: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var members: [User]
    var expenses: [Expense]
}
