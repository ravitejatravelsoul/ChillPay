import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Welcome to ChillPay")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("Split bills, track expenses, and stay chill with friends!")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ChillTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            Spacer(minLength: 60)
        }
        .background(ChillTheme.background.ignoresSafeArea())
    }
}
