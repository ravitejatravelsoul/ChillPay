import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    var onVerified: () -> Void
    var onLogout: () -> Void

    @State private var sent = false
    @State private var errorMessage: String?
    @State private var canResend = true
    @State private var cooldownSeconds = 60
    @State private var remainingSeconds = 0

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Verify Your Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)

                    Text("We’ve sent a verification link to your email. Please check your inbox (and spam folder).")
                        .font(.title3)
                        .foregroundColor(ChillTheme.darkText.opacity(0.8))
                        .multilineTextAlignment(.center)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    } else if sent {
                        Text("Verification email sent!")
                            .foregroundColor(ChillTheme.accent)
                            .fontWeight(.semibold)
                    }

                    ChillPrimaryButton(
                        title: resendTitle,
                        isDisabled: !canResend,
                        systemImage: "envelope"
                    ) {
                        resendVerificationEmail()
                    }

                    ChillPrimaryButton(
                        title: "I Verified My Email",
                        isDisabled: false,
                        systemImage: "checkmark.seal"
                    ) {
                        verifyNow()
                    }

                    Button(action: onLogout) {
                        Text("Logout")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ChillTheme.card)
                            .foregroundColor(.red)
                            .cornerRadius(14)
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .shadow(color: ChillTheme.lightShadow, radius: 8, x: 0, y: 2)

                Spacer()
            }
        }
        // ✅ iOS 17+ onChange signature (two params)
        .onChange(of: remainingSeconds) { _, newValue in
            if newValue <= 0 {
                canResend = true
            }
        }
    }

    private var resendTitle: String {
        canResend ? "Resend Verification Email" : "Resend in \(remainingSeconds)s"
    }

    private func resendVerificationEmail() {
        errorMessage = nil
        sent = false

        guard canResend else { return }
        guard let user = Auth.auth().currentUser else {
            errorMessage = "You’re not signed in. Please login again."
            return
        }

        canResend = false
        remainingSeconds = cooldownSeconds

        user.sendEmailVerification { error in
            if let error = error {
                #if DEBUG
                print("Resend verification error: \(error.localizedDescription)")
                #endif
                errorMessage = "We couldn’t resend the email. Please try again in a moment."
                remainingSeconds = 10
                startCountdown()
            } else {
                sent = true
                errorMessage = nil
                startCountdown()
            }
        }
    }

    private func startCountdown() {
        guard remainingSeconds > 0 else {
            canResend = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            remainingSeconds -= 1
            if remainingSeconds > 0 {
                startCountdown()
            } else {
                canResend = true
            }
        }
    }

    private func verifyNow() {
        errorMessage = nil

        Auth.auth().currentUser?.reload { _ in
            guard let user = Auth.auth().currentUser else {
                errorMessage = "You’re not signed in. Please login again."
                return
            }

            if user.isEmailVerified {
                onVerified()
            } else {
                errorMessage = "Still not verified. Please click the link in your email and try again."
            }
        }
    }
}
