import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var authService = AuthService.shared
    // Load initial values from user, fallback if nil
    @State private var selectedAvatar: String? = AuthService.shared.user?.avatar
    @State private var name: String = AuthService.shared.user?.name ?? ""
    @State private var phone: String = AuthService.shared.user?.phone ?? ""
    @State private var bio: String = AuthService.shared.user?.bio ?? ""
    @State private var errorMessage: String?

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
                    ChillTextField(title: "Phone (optional)", text: $phone)
                    ChillTextField(title: "Bio (optional)", text: $bio)
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

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    if let emoji = selectedAvatar, !name.isEmpty {
                        authService.updateProfile(
                            name: name,
                            phone: phone,
                            bio: bio,
                            avatar: emoji
                        )
                    } else {
                        errorMessage = "Please fill all required fields and pick an avatar."
                    }
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAvatar != nil && !name.isEmpty ? ChillTheme.accent : Color.gray.opacity(0.5))
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
