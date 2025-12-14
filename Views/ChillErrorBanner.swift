import SwiftUI

/// A reusable banner for presenting error messages to the user.
///
/// The banner appears at the top of a view and uses a tinted red background
/// with rounded corners. It displays the provided error text and includes a
/// dismiss button on the trailing edge. The dismissal action is handled by
/// the parent view via a binding to the presented flag.
struct ChillErrorBanner: View {
    /// The message to display in the banner. Keep this succinct and
    /// user‑friendly. Avoid exposing raw error codes.
    let message: String
    /// Binding controlling whether the banner is visible. When set to `false`
    /// the banner is hidden.
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .lineLimit(3)
                Spacer()
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red.opacity(0.85))
            .cornerRadius(ChillTheme.cardRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding([.horizontal, .top])
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}