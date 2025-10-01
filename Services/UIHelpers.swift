import SwiftUI

struct ChillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(12)
            .background(ChillTheme.softGray.opacity(0.15))
            .cornerRadius(12)
            .foregroundColor(.white)
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
