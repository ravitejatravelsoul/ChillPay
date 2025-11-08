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

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                if let user = authService.user {
                    VStack(spacing: 16) {
                        // DiceBear Avatar Setup: Display DiceBear PNG avatar if available, otherwise fallback to emoji
                        if !user.avatarSeed.isEmpty && !user.avatarStyle.isEmpty {
                            let avatarUrl = "https://api.dicebear.com/7.x/\(user.avatarStyle)/png?seed=\(user.avatarSeed)"
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(Circle())
                                    .frame(width: 80, height: 80)
                                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 3))
                                    .padding(.bottom, 8)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 80, height: 80)
                                    .padding(.bottom, 8)
                            }
                        } else {
                            Text(user.avatar ?? "🙂")
                                .font(.system(size: 80))
                                .padding(.bottom, 8)
                        }
                        Text(user.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        if let phone = user.phone, !phone.isEmpty {
                            Text("Phone: \(phone)")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.footnote)
                                .italic()
                                .padding(.top, 4)
                        }
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
                
                VStack(spacing: 20) {
                    Button(action: { showEditProfile = true }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.white)
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
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        authService.updateNotificationsEnabled(newValue)
                    }
                    
                    Toggle(isOn: $faceIDEnabled) {
                        Label("Use Face ID", systemImage: "faceid")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 32)
                    .onChange(of: faceIDEnabled) { _, newValue in
                        authService.updateFaceIDEnabled(newValue)
                    }
                    
                    Button(action: { showPaymentsSheet = true }) {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.white)
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
                                .foregroundColor(.white)
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
                                .foregroundColor(.red)
                            Text("Logout")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundColor(.red)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .alert("Log Out", isPresented: $showLogoutSheet) {
                        Button("Log Out", role: .destructive) {
                            authService.signOut()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Are you sure you want to log out?")
                    }
                }
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            if authService.user == nil, let currentUser = Auth.auth().currentUser {
                authService.fetchUserDocument(uid: currentUser.uid)
            }
            notificationsEnabled = authService.user?.notificationsEnabled ?? true
            faceIDEnabled = authService.user?.faceIDEnabled ?? false
        }
        .preferredColorScheme(.dark)
    }
}
