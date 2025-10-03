import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    var onVerified: () -> Void
    var onLogout: () -> Void
    @State private var sent = false
    @State private var errorMessage: String?
    @State private var canResend = true
    @State private var cooldownSeconds = 60

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Verify Your Email")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Text("We've sent a verification link to your email. Please check your inbox (and spam folder).")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if sent {
                Text("Verification email sent!")
                    .foregroundColor(.green)
            }

            Button("Resend Verification Email") {
                errorMessage = nil
                if let user = Auth.auth().currentUser, canResend {
                    user.sendEmailVerification { error in
                        if let error = error {
                            errorMessage = "Failed to send: \(error.localizedDescription)"
                            sent = false
                            // Allow another attempt after 10 seconds if blocked
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                canResend = true
                            }
                        } else {
                            sent = true
                            errorMessage = nil
                            canResend = false
                            // Cooldown before allowing another resend
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(cooldownSeconds)) {
                                canResend = true
                            }
                        }
                    }
                }
            }
            .font(.headline)
            .padding()
            .background(Color(.sRGB, white: 0.12, opacity: 1))
            .foregroundColor(.white)
            .cornerRadius(14)
            .disabled(!canResend)
            .opacity(canResend ? 1 : 0.5)

            Button("I Verified My Email") {
                errorMessage = nil
                Auth.auth().currentUser?.reload(completion: { _ in
                    if let user = Auth.auth().currentUser, user.isEmailVerified {
                        onVerified()
                    } else {
                        errorMessage = "Still not verified. Please click the link in your email and try again."
                    }
                })
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(14)

            Button("Logout") { onLogout() }
                .foregroundColor(.red)
            Spacer()
        }
        .background(ChillTheme.background.ignoresSafeArea())
    }
}
