import SwiftUI

struct ChillTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder shown only when the field is empty. Use the theme's soft gray for subtlety.
            if text.isEmpty {
                Text(title)
                    .foregroundColor(ChillTheme.softGray)
                    .padding(.horizontal, 16)
            }
            // Show either a SecureField or TextField depending on the `isSecure` flag. Use the
            // theme's dark text colour for the entered text and bind the focus state.
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(ChillTheme.darkText)
                    .padding(.horizontal, 16)
                    .focused($isFocused)
            } else {
                TextField("", text: $text)
                    .foregroundColor(ChillTheme.darkText)
                    .padding(.horizontal, 16)
                    .focused($isFocused)
            }
        }
        .frame(height: 52)
        .background(ChillTheme.card)
        // Draw a border that highlights when the field is focused. When focused use the accent colour,
        // otherwise use a subtle soft gray. This makes the input bounds clear in both light and dark modes.
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? ChillTheme.accent : ChillTheme.softGray, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}
