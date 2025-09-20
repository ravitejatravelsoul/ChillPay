import Foundation

/// Categories that an `Expense` can belong to.  New values can be added as
/// needed; case names double as raw values for easy persistence.
enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case travel
    case accommodation
    case utilities
    case entertainment
    case shopping
    case other
    
    var id: String { rawValue }
    
    /// Human‑readable display names for each category.
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
