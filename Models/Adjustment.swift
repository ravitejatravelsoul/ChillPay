import Foundation

struct Adjustment: Identifiable, Codable, Hashable {
    let id: UUID
    var from: User
    var to: User
    var amount: Double
    var date: Date
}
