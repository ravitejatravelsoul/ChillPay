import SwiftUI

struct ChillTheme {
    /// Base background color.  For a light-first design, we rely on the system background which adapts to light/dark mode.
    static let background = Color(.systemBackground)
    /// Card backgrounds provide subtle contrast on the main backdrop.  We use the secondary system background to ensure
    /// grouped content stands out without being too dark.
    static let card = Color(.secondarySystemBackground)
    /// Primary accent color used throughout the app.  Stick with the system blue to feel native on iOS.
    static let accent = Color(.systemBlue)
    /// Chip colors for money owed/owing.  Use system colours to automatically adjust for light/dark.
    static let chipOwe = Color(.systemOrange)
    static let chipOwed = Color(.systemGreen)
    /// Soft gray for separators and secondary text.
    static let softGray = Color(.systemGray3)
    /// Default text colour used on light backgrounds.  We defer to the system primary label colour so that
    /// text remains legible in both light and dark modes.
    static let darkText = Color.primary
    /// Tab bar background uses the same as the main background to blend seamlessly.
    static let tabBar = Color(.systemBackground)

    /// Dashboard gradient for the total balance card.  Use a subtle blend of the accent colour and a secondary tint.
    static let dashboardGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemBlue).opacity(0.6), Color(.systemTeal).opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Consistent with previous references
    static let cardRadius: CGFloat = 20
    static let cardShadow: CGFloat = 8
    static let chipRadius: CGFloat = 14

    // Add these aliases for compatibility:
    static let cornerRadius: CGFloat = cardRadius
    static let shadowRadius: CGFloat = cardShadow
    static let lightShadow = Color.black.opacity(0.08)

    static let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 13, weight: .medium, design: .rounded)
}
