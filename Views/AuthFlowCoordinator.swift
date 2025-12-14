import SwiftUI
import FirebaseAuth

enum AuthFlowScreen {
    case onboarding, login, signup, emailVerification, mainApp
}

struct AuthFlowCoordinator: View {
    @State private var flowScreen: AuthFlowScreen = .onboarding
    @ObservedObject var authService = AuthService.shared
    @State private var globalMessage: String? = nil
    @State private var isFromSignup: Bool = false // Track if coming from signup

    // MARK: - Password Reset Deep Link
    /// When non‑nil, stores an out‑of‑band code extracted from a Firebase reset
    /// password link. Triggering this will present a ResetPasswordView.
    @State private var resetOobCode: String? = nil
    @State private var showResetPassword: Bool = false
    
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack {
                if let globalMessage = globalMessage {
                    Text(globalMessage)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.top, 30)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer(minLength: 0)
            }
            .zIndex(2)
            
            switch flowScreen {
            case .onboarding:
                OnboardingView {
                    flowScreen = .login
                }
            case .login:
                LoginView(
                    onSignup: { flowScreen = .signup },
                    onLoginSuccess: {
                        setCurrentUserFromProfile()
                        // On login, skip verify screen, go directly to dashboard
                        flowScreen = .mainApp
                        isFromSignup = false
                    },
                    onLoginError: { error in
                        globalMessage = error
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            globalMessage = nil
                        }
                    }
                )
            case .signup:
                SignupView(
                    onSignupSuccess: {
                        isFromSignup = true
                        flowScreen = .emailVerification
                    },
                    onBack: { flowScreen = .login }
                )
            case .emailVerification:
                EmailVerificationView(
                    onVerified: { flowScreen = .login },
                    onLogout: { flowScreen = .login }
                )
            case .mainApp:
                ContentView()
            }
        }
        .onAppear { restoreSessionIfPossible() }
        .onChange(of: authService.isAuthenticated) { _, _ in syncFlowOnAuthChange() }
        .onChange(of: authService.user) { _, _ in syncFlowOnAuthChange() }

        // Present reset password screen when a code has been captured
        .fullScreenCover(isPresented: $showResetPassword) {
            if let code = resetOobCode {
                ResetPasswordView(oobCode: code) {
                    // Completion: clear the code and ensure login screen is shown
                    resetOobCode = nil
                    showResetPassword = false
                    flowScreen = .login
                }
            }
        }

        // Handle incoming URLs to support password reset deep links. Looks for
        // Firebase reset password links (mode=resetPassword & oobCode=...).
        .onOpenURL { url in
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
            let queryItems = components.queryItems ?? []
            let mode = queryItems.first(where: { $0.name == "mode" })?.value
            let code = queryItems.first(where: { $0.name == "oobCode" })?.value
            if mode == "resetPassword", let code = code {
                // Store and show reset view.
                resetOobCode = code
                showResetPassword = true
            }
        }
    }

    private func restoreSessionIfPossible() {
        if let currentUser = Auth.auth().currentUser {
            authService.setUser(from: currentUser)
            setCurrentUserFromProfile()
            flowScreen = .mainApp // On restore, always go to dashboard
            isFromSignup = false
        } else {
            flowScreen = .login
        }
    }

    private func syncFlowOnAuthChange() {
        // Only on first signup, show verify email. All other times, go to dashboard.
        if authService.isAuthenticated, authService.user != nil {
            setCurrentUserFromProfile()
            if isFromSignup {
                flowScreen = .emailVerification
            } else {
                flowScreen = .mainApp
            }
        } else {
            flowScreen = .login
        }
    }

    /// ⬇️ IMPORTANT: always propagate avatar fields into the lightweight `User`
    private func setCurrentUserFromProfile() {
        guard let profile = authService.user else { return }

        let user = User(
            id: profile.uid,
            name: profile.name,
            email: profile.email,
            avatar: profile.avatar,
            avatarSeed: profile.avatarSeed,
            avatarStyle: profile.avatarStyle
        )

        FriendsViewModel.shared.currentUser = user
        FriendsViewModel.shared.refreshFriends()
    }
}
