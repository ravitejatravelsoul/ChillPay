import SwiftUI

struct BiometricGateView: View {
    let onUnlocked: () -> Void
    let onUsePasswordInstead: () -> Void

    @State private var errorText: String?
    private let bio = BiometricAuthService.shared

    private var titleText: String {
        switch bio.biometricType() {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        case .none: return "Unlock"
        }
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: bio.biometricType() == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundColor(ChillTheme.accent)

                Text(titleText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(ChillTheme.darkText)

                Text("ChillPay is locked to protect your expenses.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let errorText {
                    Text(errorText)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    ChillPrimaryButton(
                        title: "Unlock",
                        isDisabled: false,
                        systemImage: "lock.open"
                    ) {
                        unlock()
                    }

                    Button("Use Password Instead") {
                        onUsePasswordInstead()
                    }
                    .font(.headline)
                    .foregroundColor(ChillTheme.accent)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            // Auto-trigger Face ID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                unlock()
            }
        }
    }

    private func unlock() {
        errorText = nil
        bio.authenticate(reason: "Unlock ChillPay to continue.") { success in
            if success {
                onUnlocked()
            } else {
                errorText = "Couldn’t verify. Please try again."
            }
        }
    }
}
