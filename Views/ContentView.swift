import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var showAddSheet = false

    @StateObject private var friendsVM: FriendsViewModel
    @StateObject private var groupVM: GroupViewModel
    @ObservedObject private var authService = AuthService.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    // MARK: - Face ID Gate State
    @State private var isBiometricUnlocked: Bool = false

    /// Read from Firestore-backed user profile
    private var biometricLockEnabled: Bool {
        authService.user?.faceIDEnabled ?? false
    }

    /// Show gate only when required
    private var shouldShowBiometricGate: Bool {
        guard authService.user != nil else { return false }
        guard biometricLockEnabled else { return false }
        return !isBiometricUnlocked
    }

    init() {
        let f = FriendsViewModel.shared
        _friendsVM = StateObject(wrappedValue: f)
        _groupVM = StateObject(wrappedValue: GroupViewModel(friendsVM: f))
    }

    // MARK: - Main Tabs
    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .home:
            DashboardView(selectedTab: $selectedTab)
                .environmentObject(groupVM)
                .environmentObject(friendsVM)
                .padding(.bottom, 72)

        case .friends:
            NavigationView {
                FriendsView(friendsVM: friendsVM)
            }
            .padding(.bottom, 72)

        case .groups:
            NavigationView {
                GroupListView(groupVM: groupVM, friendsVM: friendsVM)
            }
            .padding(.bottom, 72)

        case .activity:
            NavigationView {
                ActivitiesView()
                    .environmentObject(groupVM)
            }
            .padding(.bottom, 72)

        case .profile:
            NavigationView {
                ProfileView()
            }
            .padding(.bottom, 72)
        }
    }

    var body: some View {
        ZStack {
            mainContent

            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showAddSheet: $showAddSheet,
                    user: authService.user
                )
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(groupVM)
        .environmentObject(friendsVM)

        .sheet(isPresented: $showAddSheet) {
            AddGroupView(groupVM: groupVM, friendsVM: friendsVM)
        }

        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }

        // ✅ Face ID Gate (correct initializer)
        .fullScreenCover(isPresented: .constant(shouldShowBiometricGate)) {
            BiometricGateView(
                onUnlocked: {
                    // Successful biometric authentication unlocks the app
                    isBiometricUnlocked = true
                },
                onUsePasswordInstead: {
                    // User chooses to use password instead → require full login
                    // Do not unlock; instead sign out and reset the unlocked flag
                    isBiometricUnlocked = false
                    AuthService.shared.signOut()
                }
            )
        }

        // MARK: - Onboarding
        .task {
            if authService.user != nil && !hasSeenOnboarding {
                try? await Task.sleep(nanoseconds: 300_000_000)
                showOnboarding = true
            }
        }

        // MARK: - Reset on Login / Logout
        .onChange(of: authService.user?.id) { _, newValue in
            if newValue == nil {
                // Logged out
                showOnboarding = false
                isBiometricUnlocked = false
            } else {
                // Logged in
                isBiometricUnlocked = false
            }
        }
    }
}
