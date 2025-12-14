
import SwiftUI
import FirebaseAuth

/// Forgot Password screen:
/// - Email field
/// - "Send Reset Link" button
/// - Loading state
/// - Success/Error banner
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isLoading: Bool = false

    @State private var bannerMessage: String? = nil
    @State private var bannerIsError: Bool = false
    @State private var showBanner: Bool = false

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("Forgot Password")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(ChillTheme.darkText)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Text("Enter your email and we’ll send you a password reset link.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.leading)

                VStack(spacing: 14) {
                    ChillTextField(title: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 20)

                Button {
                    sendReset()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Send Reset Link")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(ChillTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal, 20)
                .disabled(isLoading)

                Spacer()
            }

            if showBanner, let msg = bannerMessage {
                BannerView(message: msg, isError: bannerIsError) {
                    withAnimation { showBanner = false }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            show(message: "Please enter your email.", isError: true)
            return
        }

        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    show(message: error.localizedDescription, isError: true)
                } else {
                    show(message: "Reset email sent. Check your inbox.", isError: false)
                }
            }
        }
    }

    private func show(message: String, isError: Bool) {
        bannerMessage = message
        bannerIsError = isError
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { showBanner = false }
        }
    }
}

private struct BannerView: View {
    let message: String
    let isError: Bool
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(.white)

            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
                .lineLimit(3)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background((isError ? Color.red : Color.green).opacity(0.88))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
