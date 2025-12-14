
import SwiftUI
import FirebaseAuth

/// Reset Password screen presented when app opens with:
/// ?mode=resetPassword&oobCode=XXXX
struct ResetPasswordView: View {
    let oobCode: String
    let onFinished: () -> Void

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @State private var showNew: Bool = false
    @State private var showConfirm: Bool = false

    @State private var isLoading: Bool = false
    @State private var bannerMessage: String? = nil
    @State private var bannerIsError: Bool = false
    @State private var showBanner: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("Reset Password")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(ChillTheme.darkText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Text("Create a new password for your account.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    passwordRow(
                        title: "New Password",
                        text: $newPassword,
                        isVisible: $showNew
                    )

                    passwordRow(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        isVisible: $showConfirm
                    )

                    validationHints
                }
                .padding(.horizontal, 20)

                Button {
                    updatePassword()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Update Password")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(canSubmit ? ChillTheme.accent : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal, 20)
                .disabled(!canSubmit || isLoading)

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

    private var canSubmit: Bool {
        passwordMeetsRules(newPassword) && newPassword == confirmPassword
    }

    private var validationHints: some View {
        VStack(alignment: .leading, spacing: 6) {
            ruleRow(text: "Minimum 12 characters", met: newPassword.count >= 12)
            ruleRow(text: "At least 1 special character", met: containsSpecial(newPassword))
            // Bonus rules (optional but helpful)
            ruleRow(text: "At least 1 uppercase letter (bonus)", met: containsUppercase(newPassword))
            ruleRow(text: "At least 1 number (bonus)", met: containsNumber(newPassword))
            ruleRow(text: "Passwords match", met: !confirmPassword.isEmpty && newPassword == confirmPassword)
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.top, 6)
    }

    private func passwordRow(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack {
            if isVisible.wrappedValue {
                TextField(title, text: text)
                    .textInputAutocapitalization(.never)
            } else {
                SecureField(title, text: text)
                    .textInputAutocapitalization(.never)
            }

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
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
    }

    private func updatePassword() {
        guard canSubmit else { return }
        isLoading = true

        Auth.auth().confirmPasswordReset(withCode: oobCode, newPassword: newPassword) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    show(message: error.localizedDescription, isError: true)
                    return
                }

                show(message: "Password updated successfully. Please login again.", isError: false)

                // Requirement: DO NOT auto-login after reset.
                // (Also safe to signOut if someone was logged in.)
                try? Auth.auth().signOut()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onFinished()
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

    // MARK: - Validation

    private func passwordMeetsRules(_ password: String) -> Bool {
        password.count >= 12 && containsSpecial(password)
    }

    private func containsSpecial(_ s: String) -> Bool {
        let specialSet = CharacterSet(charactersIn: "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/`~\\")
        return s.rangeOfCharacter(from: specialSet) != nil
    }

    private func containsUppercase(_ s: String) -> Bool {
        s.rangeOfCharacter(from: .uppercaseLetters) != nil
    }

    private func containsNumber(_ s: String) -> Bool {
        s.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private func ruleRow(text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
            Text(text)
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
