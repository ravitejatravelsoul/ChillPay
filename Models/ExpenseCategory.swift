import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case food, travel, accommodation, utilities, entertainment, shopping, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .food: return "Food"
        case .travel: return "Travel"
        case .accommodation: return "Accommodation"
        case .utilities: return "Utilities"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }
}
