import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    // Profile avatar placeholder
                    ZStack {
                        Circle()
                            .fill(ChillTheme.card)
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.95))
                    }
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 32)

                VStack(alignment: .center, spacing: 18) {
                    Text("Profile info, settings, and payment platform integration coming soon!")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding(.horizontal, 16)
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(20)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
