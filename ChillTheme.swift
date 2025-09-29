import SwiftUI

struct ChillTheme {
    static let background = Color(.sRGB, red: 19/255, green: 22/255, blue: 29/255, opacity: 1)
    static let card = Color(.sRGB, white: 0.13, opacity: 1)
    static let accent = Color.green
    static let chipOwe = Color.orange
    static let chipOwed = Color.cyan
    static let softGray = Color(.sRGB, white: 0.88, opacity: 1)
    static let darkText = Color.white
    static let tabBar = Color(.sRGB, white: 0.09, opacity: 1)

    static let dashboardGradient = LinearGradient(
        gradient: Gradient(colors: [Color.purple, Color.blue]),
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
    static let lightShadow = Color.black.opacity(0.13)

    static let headerFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 13, weight: .medium, design: .rounded)
}
