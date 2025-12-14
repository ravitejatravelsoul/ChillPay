import SwiftUI

struct LoginView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    var onSignup: () -> Void
    var onLoginSuccess: () -> Void
    var onLoginError: ((String) -> Void)? = nil // Optional error callback for coordinator

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            // Header for the login screen.  Use the theme's header font and dark text colour for visibility
            Text("Login")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ChillTheme.darkText)

            VStack(spacing: 18) {
                ChillTextField(title: "Email", text: $email)
                ChillTextField(title: "Password", text: $password, isSecure: true)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 20)

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
                                email: userProfile.email
                            )
                            if authService.isEmailVerified {
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
            .disabled(authService.isCreatingUserProfile) // Block login while creating user profile

            Button("Forgot Password?") {
                if email.isEmpty {
                    errorMessage = "Enter your email above to reset password."
                } else {
                    AuthService.shared.sendPasswordReset(email: email)
                    errorMessage = "Password reset email sent (if account exists)."
                }
            }
            .foregroundColor(ChillTheme.accent)

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
