import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable {
    case food, travel, rent, shopping, entertainment, utilities, other

    var displayName: String {
        switch self {
        case .food: return "Food"
        case .travel: return "Travel"
        case .rent: return "Rent"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .utilities: return "Utilities"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🍽"
        case .travel: return "✈️"
        case .rent: return "🏠"
        case .shopping: return "🛍"
        case .entertainment: return "🎬"
        case .utilities: return "💡"
        case .other: return "🌀"
        }
    }

    var color: Color {
        switch self {
        case .food: return .green
        case .travel: return .blue
        case .rent: return .purple
        case .shopping: return .orange
        case .entertainment: return .pink
        case .utilities: return .yellow
        case .other: return .gray
        }
    }
}
