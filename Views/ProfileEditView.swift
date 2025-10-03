import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var selectedAvatar: String? = AuthService.shared.user?.avatar
    @State private var name: String = AuthService.shared.user?.name ?? ""

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text("Edit Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 32)

                VStack(spacing: 18) {
                    ChillTextField(title: "Name", text: $name)
                    Text("Avatar")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.85))

                    EmojiAvatarPicker(selectedAvatar: $selectedAvatar)
                        .padding(.horizontal, 4)
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(20)
                .padding(.horizontal, 18)

                Button(action: {
                    if let emoji = selectedAvatar {
                        authService.updateAvatar(emoji: emoji)
                    }
                    // You may want to update the name as well in your AuthService
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAvatar != nil ? ChillTheme.accent : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .disabled(selectedAvatar == nil || name.isEmpty)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
