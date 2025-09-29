import Foundation

struct Adjustment: Identifiable, Codable, Hashable {
    let id: UUID
    let from: ChillPay.User
    let to: ChillPay.User
    let amount: Double
    let date: Date
}
