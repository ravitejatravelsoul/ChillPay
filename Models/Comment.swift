import Foundation

struct Comment: Identifiable, Hashable, Codable {
    let id: UUID
    let user: ChillPay.User
    let text: String
    let date: Date
}
