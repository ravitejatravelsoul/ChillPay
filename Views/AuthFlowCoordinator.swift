import SwiftUI
import FirebaseAuth

enum AuthFlowScreen {
    case onboarding, login, signup, emailVerification, mainApp
}

struct AuthFlowCoordinator: View {
    @State private var flowScreen: AuthFlowScreen = .onboarding
    @ObservedObject var authService = AuthService.shared
    @State private var globalMessage: String? = nil

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
                        if AuthService.shared.isEmailVerified {
                            flowScreen = .mainApp
                        } else {
                            globalMessage = nil
                            flowScreen = .emailVerification
                        }
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
                    onSignupSuccess: { flowScreen = .emailVerification },
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
        .onAppear {
            // --- Persistent login fix ---
            if let currentUser = Auth.auth().currentUser {
                AuthService.shared.setUser(from: currentUser)
                setCurrentUserFromProfile()
                if AuthService.shared.isEmailVerified {
                    flowScreen = .mainApp
                } else {
                    flowScreen = .emailVerification
                }
            } else {
                flowScreen = .login
            }
        }
        .onChange(of: authService.isAuthenticated) {
            if !authService.isAuthenticated {
                flowScreen = .login
            }
        }
    }

    // Helper to always set currentUser using the existing User object from friends
    private func setCurrentUserFromProfile() {
        if let userProfile = AuthService.shared.user {
            let myUid = userProfile.uid
            if let existing = FriendsViewModel.shared.friends.first(where: { $0.id == myUid }) {
                FriendsViewModel.shared.currentUser = existing
            } else {
                let user = User(id: myUid, name: userProfile.name, email: userProfile.email)
                FriendsViewModel.shared.friends.append(user)
                FriendsViewModel.shared.currentUser = user
            }
        }
    }
}
