import SwiftUI

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
                    onSignupSuccess: {
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
        .onAppear {
            if authService.isAuthenticated && authService.isEmailVerified {
                flowScreen = .mainApp
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            // If user logs out or is deleted, always return to login
            if !isAuthenticated {
                flowScreen = .login
            }
        }
    }
}
