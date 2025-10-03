import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var authService = AuthService.shared

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                if let user = authService.user {
                    VStack(spacing: 16) {
                        Text(user.avatar ?? "🙂")
                            .font(.system(size: 80))
                            .padding(.bottom, 8)
                        Text(user.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(24)
                    .shadow(radius: 12)
                    .padding(.horizontal, 16)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                        .scaleEffect(1.5)
                }
                Spacer()
                Button(action: {
                    authService.signOut()
                }) {
                    Text("Logout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ChillTheme.card)
                        .foregroundColor(.red)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }
                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            // Try to reload user if not present (for persistence)
            if authService.user == nil, let currentUser = Auth.auth().currentUser {
                authService.fetchUserDocument(uid: currentUser.uid)
            }
        }
    }
}
