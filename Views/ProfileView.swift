import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showPaymentsSheet = false
    @State private var showEditProfile = false
    @State private var showContactSheet = false
    @State private var showLogoutSheet = false

    @State private var notificationsEnabled: Bool = AuthService.shared.user?.notificationsEnabled ?? true
    @State private var faceIDEnabled: Bool = AuthService.shared.user?.faceIDEnabled ?? false

    /// Flag stored in user defaults to track if the onboarding has been displayed.  Exposed here to allow
    /// users to re-show the onboarding from the Profile tab.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = true

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {

                Spacer().frame(height: 40)

                // MARK: User Card
                if let profile = authService.user {

                    let lightweight = User(
                        id: profile.uid,
                        name: profile.name,
                        email: profile.email,
                        avatar: profile.avatar,
                        avatarSeed: profile.avatarSeed,
                        avatarStyle: profile.avatarStyle
                    )

                    VStack(spacing: 16) {

                        AvatarView(user: lightweight, size: 80)
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 3))
                            .padding(.bottom, 8)

                        Text(profile.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(ChillTheme.darkText)

                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(ChillTheme.darkText.opacity(0.6))

                        if let phone = profile.phone, !phone.isEmpty {
                            Text("Phone: \(phone)")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .font(.subheadline)
                        }

                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .foregroundColor(ChillTheme.darkText.opacity(0.7))
                                .font(.footnote)
                                .italic()
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(24)
                    .shadow(color: ChillTheme.lightShadow, radius: 12, x: 0, y: 2)
                    .padding(.horizontal, 16)

                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ChillTheme.accent))
                        .scaleEffect(1.5)
                }

                // MARK: Buttons
                VStack(spacing: 20) {

                    Button(action: { showEditProfile = true }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("Edit Profile")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ChillTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .sheet(isPresented: $showEditProfile) {
                        ProfileEditView()
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Enable Notifications", systemImage: "bell")
                            .foregroundColor(ChillTheme.darkText)
                    }
                    .padding(.horizontal, 32)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        authService.updateNotificationsEnabled(newValue)
                    }

                    Toggle(isOn: $faceIDEnabled) {
                        Label("Use Face ID", systemImage: "faceid")
                            .foregroundColor(ChillTheme.darkText)
                    }
                    .padding(.horizontal, 32)
                    .onChange(of: faceIDEnabled) { _, newValue in
                        authService.updateFaceIDEnabled(newValue)
                    }

                    Button(action: { showPaymentsSheet = true }) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Payments")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .sheet(isPresented: $showPaymentsSheet) {
                        VStack(spacing: 22) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("Payments Coming Soon")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.primary)

                            Button("Close") { showPaymentsSheet = false }
                                .foregroundColor(.blue)
                                .padding(.top, 12)
                        }
                        .padding()
                    }

                    Button(action: { showContactSheet = true }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Contact Us")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .sheet(isPresented: $showContactSheet) {
                        VStack(spacing: 18) {
                            Image(systemName: "envelope")
                                .font(.system(size: 36))
                                .foregroundColor(.green)

                            Text("Contact us at support@chillpay.com\nor reach out via WhatsApp!")
                                .multilineTextAlignment(.center)
                                .font(.body)

                            Button("Close") { showContactSheet = false }
                                .foregroundColor(.blue)
                                .padding(.top, 12)
                        }
                        .padding()
                    }

                    Button(action: { showLogoutSheet = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ChillTheme.card)
                        .foregroundColor(.red)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .alert("Log Out", isPresented: $showLogoutSheet) {
                        Button("Log Out", role: .destructive) {
                            authService.signOut()   // FIXED
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to log out?")
                    }

                    // Button to allow the user to view onboarding again
                    Button(action: {
                        // Reset the onboarding flag – ContentView will show onboarding on next appearance
                        hasSeenOnboarding = false
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Show Onboarding Again")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ChillTheme.card)
                        .foregroundColor(ChillTheme.accent)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            if authService.user == nil,
               let currentUser = Auth.auth().currentUser {
                authService.fetchUserDocument(uid: currentUser.uid)
            }
            notificationsEnabled = authService.user?.notificationsEnabled ?? true
            faceIDEnabled = authService.user?.faceIDEnabled ?? false
        }
        // Do not force dark mode; rely on system appearance
    }
}
