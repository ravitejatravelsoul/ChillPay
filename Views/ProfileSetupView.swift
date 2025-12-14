import SwiftUI

struct ProfileSetupView: View {
    @State private var name: String = ""
    @State private var selectedAvatar: String? = nil
    @ObservedObject var authService = AuthService.shared

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Set Up Your Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)
                    Text("Choose a name and pick your avatar to get started.")
                        .font(.headline)
                        .foregroundColor(ChillTheme.darkText.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 18) {
                    ChillTextField(title: "Your Name", text: $name)

                    Text("Pick Your Avatar")
                        .font(.headline)
                        .foregroundColor(ChillTheme.darkText.opacity(0.85))

                    EmojiAvatarPicker(selectedAvatar: $selectedAvatar)
                        .padding(.horizontal, 4)
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(20)
                .padding(.horizontal, 18)

                Button(action: {
                    // Use selectedAvatar and name in your sign up flow
                    // You can call your AuthService sign up here, e.g.:
                    // authService.signUpWithEmail(email: email, password: password, name: name, avatar: avatar)
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((selectedAvatar != nil && !name.isEmpty) ? ChillTheme.accent : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .disabled(selectedAvatar == nil || name.isEmpty)

                Spacer()
            }
        }
        // Do not force dark mode; rely on system appearance
    }
}
