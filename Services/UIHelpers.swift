import SwiftUI

struct ChillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        // For a light‑first design, use dark text on a subtle card background with
        // an accent‑coloured cursor. Avoid hard‑coded white text which would be
        // invisible on a light background. Provide padding for comfortable typing
        // and use the same rounded font as elsewhere in the app.
        configuration
            .padding(12)
            // Card colour differentiates the field from the main page while
            // remaining compatible with both light and dark modes.
            .background(ChillTheme.card)
            .cornerRadius(12)
            // Draw a subtle border around the field so its bounds are clear in
            // both light and dark mode. Using the softGray colour ensures
            // sufficient contrast without being overpowering. The border
            // thickness is kept light for a modern look.
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ChillTheme.softGray, lineWidth: 1)
            )
            // Ensure typed text is legible on light backgrounds.
            .foregroundColor(ChillTheme.darkText)
            // Accent colour for the text cursor
            .accentColor(ChillTheme.accent)
            .font(.system(size: 17, weight: .regular, design: .rounded))
    }
}

// Custom placeholder for any SwiftUI View
extension View {
    func chillPlaceholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
