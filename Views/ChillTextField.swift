import SwiftUI

struct ChillTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(title)
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 16)
            }
            if isSecure {
                SecureField("", text: $text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
            } else {
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 52)
        .background(ChillTheme.card)
        .cornerRadius(16)
    }
}
