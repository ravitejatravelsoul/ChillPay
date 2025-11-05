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
        .onChange(of: authService.isAuthenticated) { _ in syncFlowOnAuthChange() }
        .onChange(of: authService.user) { _ in syncFlowOnAuthChange() }
    }

    private func restoreSessionIfPossible() {
        if let currentUser = Auth.auth().currentUser {
            authService.setUser(from: currentUser)
            setCurrentUserFromProfile()
            flowScreen = .mainApp // On restore, always go to dashboard (never verify email here)
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

    private func setCurrentUserFromProfile() {
        if let userProfile = authService.user {
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
