import SwiftUI

struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword: Bool = false
    /// Persisted Face ID preference. Reflects whether the user wants to use
    /// biometrics on next login. Updated after successful login.
    @AppStorage("faceIDEnabledPreference") private var faceIDToggle: Bool = false

    /// Controls presentation of the forgot password sheet.
    @State private var showForgotPassword: Bool = false
    @State private var errorMessage: String?
    var onSignup: () -> Void
    var onLoginSuccess: () -> Void
    var onLoginError: ((String) -> Void)? = nil // Optional error callback for coordinator

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header for the login screen. Use the theme's header font and dark text colour for visibility
            Text("Login")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ChillTheme.darkText)

            VStack(spacing: 18) {
                ChillTextField(title: "Email", text: $email)
                // Custom password field with visibility toggle
                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                            .autocapitalization(.none)
                            .foregroundColor(ChillTheme.darkText)
                    } else {
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .foregroundColor(ChillTheme.darkText)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(ChillTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ChillTheme.softGray, lineWidth: 1)
                )
                .cornerRadius(16)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 20)

            // Login button
            Button(action: {
                errorMessage = nil
                authService.signInWithEmail(
                    email: email,
                    password: password,
                    onLoginProgress: { loginMsg in
                        // This completion handler now handles all UI update + navigation!
                        if let msg = loginMsg {
                            errorMessage = msg
                            onLoginError?(msg)
                        } else if authService.isAuthenticated, let userProfile = authService.user {
                            // --- SET currentUser in FriendsViewModel after login! ---
                            FriendsViewModel.shared.currentUser = User(
                                id: userProfile.uid,
                                name: userProfile.name,
                                email: userProfile.email,
                                avatar: userProfile.avatar,
                                avatarSeed: userProfile.avatarSeed,
                                avatarStyle: userProfile.avatarStyle
                            )
                            if authService.isEmailVerified {
                                // Update Face ID preference in Firestore
                                authService.updateFaceIDEnabled(faceIDToggle)
                                onLoginSuccess()
                            } else {
                                let msg = "Please verify your email before logging in."
                                errorMessage = msg
                                onLoginError?(msg)
                            }
                        } else {
                            let msg = "Invalid credentials or user does not exist."
                            errorMessage = msg
                            onLoginError?(msg)
                        }
                    }
                )
            }) {
                if authService.isCreatingUserProfile {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(ChillTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(14)
            .padding(.horizontal, 24)
            .disabled(authService.isCreatingUserProfile)

            // Face ID toggle persists to user profile after login
            Toggle("Use Face ID next time", isOn: $faceIDToggle)
                .foregroundColor(ChillTheme.darkText)
                .padding(.horizontal, 24)
                .tint(ChillTheme.accent)

            // Forgot password link shows a modal screen
            Button(action: { showForgotPassword = true }) {
                Text("Forgot Password?")
                    .foregroundColor(ChillTheme.accent)
            }
            .padding(.top, 8)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(initialEmail: email)
            }

            HStack {
                Text("Don't have an account?")
                    .foregroundColor(ChillTheme.darkText.opacity(0.7))
                Button("Sign Up") { onSignup() }
                    .foregroundColor(ChillTheme.accent)
            }
            Spacer()
        }
        .background(ChillTheme.background.ignoresSafeArea())
    }
}
