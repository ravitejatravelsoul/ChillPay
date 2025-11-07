import SwiftUI

struct SignupView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var phone = ""                // NEW
    @State private var bio = ""                  // NEW
    @State private var notificationsEnabled = true     // NEW
    @State private var faceIDEnabled = false           // NEW
    @State private var selectedAvatar: String? = nil
    @State private var errorMessage: String?
    var onSignupSuccess: () -> Void
    var onBack: () -> Void

    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 32)
                    Text("Sign Up")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    VStack(spacing: 14) {
                        ChillTextField(title: "Name", text: $name)
                        ChillTextField(title: "Email", text: $email)
                        ChillTextField(title: "Phone (optional)", text: $phone)
                        ChillTextField(title: "Bio (optional)", text: $bio)
                        ChillTextField(title: "Password", text: $password, isSecure: true)
                        Toggle("Enable notifications", isOn: $notificationsEnabled)
                            .foregroundColor(.white)
                        Toggle("Enable Face ID", isOn: $faceIDEnabled)
                            .foregroundColor(.white)
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }.padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        Text("Pick Your Avatar")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.85))
                        EmojiAvatarPicker(selectedAvatar: $selectedAvatar)
                    }
                    .padding(.horizontal, 8)

                    Button(action: {
                        guard let avatar = selectedAvatar, !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                            errorMessage = "Please fill all required fields and pick an avatar."
                            return
                        }
                        errorMessage = nil
                        authService.signUpWithEmail(
                            email: email,
                            password: password,
                            name: name,
                            avatar: avatar,
                            bio: bio,
                            phone: phone,
                            notificationsEnabled: notificationsEnabled,
                            faceIDEnabled: faceIDEnabled,
                            onProfileCreated: {
                                onSignupSuccess()
                            }
                        )
                    }) {
                        if authService.isCreatingUserProfile {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign Up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background((selectedAvatar != nil && !name.isEmpty && !email.isEmpty && !password.isEmpty) ? ChillTheme.accent : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .disabled(selectedAvatar == nil || name.isEmpty || email.isEmpty || password.isEmpty || authService.isCreatingUserProfile) // Block button during profile creation

                    Button("Back to Login") { onBack() }
                        .foregroundColor(.green)

                    Spacer(minLength: 32)
                }
                .padding(.bottom, keyboardHeight)
                .frame(maxWidth: .infinity)
            }
            .onTapGesture { hideKeyboard() }
            .onAppear { subscribeToKeyboardNotifications() }
            .onDisappear { unsubscribeFromKeyboardNotifications() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Keyboard Handling
    private func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
            if let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let safeAreaBottom = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows.first?.safeAreaInsets.bottom ?? 0
                withAnimation {
                    keyboardHeight = rect.height - safeAreaBottom
                }
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation { keyboardHeight = 0 }
        }
    }
    private func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
