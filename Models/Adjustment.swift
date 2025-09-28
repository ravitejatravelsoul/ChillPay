import Foundation

struct Adjustment: Identifiable, Hashable, Codable {
    let id: UUID
    let from: ChillPay.User
    let to: ChillPay.User
    let amount: Double
    let date: Date
}
