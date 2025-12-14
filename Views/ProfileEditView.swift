import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var authService = AuthService.shared
    // Load initial values from user, fallback if nil
    @State private var selectedAvatar: String? = AuthService.shared.user?.avatar
    @State private var avatarSeed: String = AuthService.shared.user?.avatarSeed ?? "raviteja"
    @State private var avatarStyle: String = AuthService.shared.user?.avatarStyle ?? "adventurer"
    @State private var name: String = AuthService.shared.user?.name ?? ""
    @State private var phone: String = AuthService.shared.user?.phone ?? ""
    @State private var bio: String = AuthService.shared.user?.bio ?? ""
    @State private var errorMessage: String?

    // Tracks whether the avatar has been modified from its initial value. When true,
    // enables the "Save Avatar" button.
    @State private var avatarChanged: Bool = false
    // Feedback message for avatar save success.
    @State private var avatarSaveMessage: String? = nil

    // Presentation mode to allow dismissing this sheet after saving profile
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text("Edit Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)
                }
                .padding(.top, 32)

                VStack(spacing: 18) {
                    ChillTextField(title: "Name", text: $name)
                    ChillTextField(title: "Phone (optional)", text: $phone)
                    ChillTextField(title: "Bio (optional)", text: $bio)
                    Text("Avatar")
                        .font(.headline)
                        .foregroundColor(ChillTheme.darkText.opacity(0.85))
                    // DiceBear Avatar Picker (replace EmojiAvatarPicker if not needed anymore)
                    AvatarPickerView(avatarSeed: $avatarSeed, avatarStyle: $avatarStyle)
                        .padding(.horizontal, 4)

                    // Save Avatar button and feedback
                    Button(action: saveAvatarIfNeeded) {
                        if let msg = avatarSaveMessage {
                            Text(msg)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Save Avatar")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(avatarChanged ? ChillTheme.accent : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!avatarChanged)
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
                    if !name.isEmpty {
                        // Save both old emoji avatar (if still needed) and DiceBear avatar configs
                        authService.updateProfile(
                            name: name,
                            phone: phone,
                            bio: bio,
                            avatar: selectedAvatar ?? "",
                            avatarSeed: avatarSeed,
                            avatarStyle: avatarStyle
                        )
                        // Dismiss after saving profile
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        errorMessage = "Please fill all required fields and pick an avatar."
                    }
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((!name.isEmpty) ? ChillTheme.accent : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .disabled(name.isEmpty)

                Spacer()
            }
        }
        // Do not force dark mode; rely on system appearance
        // Track changes to avatar fields and enable the Save Avatar button accordingly
        .onChange(of: avatarSeed) { _, newValue in
            if let storedSeed = authService.user?.avatarSeed {
                avatarChanged = (newValue != storedSeed)
            } else {
                avatarChanged = true
            }
        }
        .onChange(of: avatarStyle) { _, newValue in
            if let storedStyle = authService.user?.avatarStyle {
                avatarChanged = (newValue != storedStyle)
            } else {
                avatarChanged = true
            }
        }
    }

    /// Persist the updated avatar to Firestore if it has changed, and show success feedback.
    private func saveAvatarIfNeeded() {
        guard avatarChanged else { return }
        // Persist new avatar to Firestore
        authService.updateDiceBearAvatar(seed: avatarSeed, style: avatarStyle)
        avatarSaveMessage = "Saved ✅"
        avatarChanged = false
        // Clear the success message after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            avatarSaveMessage = nil
        }
    }
}
