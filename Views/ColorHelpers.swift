import SwiftUI

/// Provides helper functions for converting between simple string names and
/// SwiftUI colours.  Groups store colour choices as lowercase strings
/// rather than storing `Color` directly because `Color` does not conform
/// to `Codable`.  When adding a new colour name here, also update
/// pickers in `AddGroupView` and `EditGroupView` accordingly.
func color(for name: String) -> Color {
    switch name.lowercased() {
    case "blue": return .blue
    case "green": return .green
    case "orange": return .orange
    case "red": return .red
    case "purple": return .purple
    case "pink": return .pink
    case "yellow": return .yellow
    case "teal": return .teal
    default: return .blue
    }
}