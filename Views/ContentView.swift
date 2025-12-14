import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var showAddSheet = false

    @StateObject private var friendsVM: FriendsViewModel
    @StateObject private var groupVM: GroupViewModel
    @ObservedObject private var authService = AuthService.shared

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    init() {
        let f = FriendsViewModel.shared
        _friendsVM = StateObject(wrappedValue: f)
        // ✅ GroupViewModel must handle starting its own Firestore listener internally
        _groupVM = StateObject(wrappedValue: GroupViewModel(friendsVM: f))
    }

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
        .task {
            // ✅ Onboarding only; group listener is handled inside GroupViewModel
            if authService.user != nil && !hasSeenOnboarding {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                showOnboarding = true
            }
        }
        // If user logs out, close onboarding if needed
        .onChange(of: authService.user?.id) { _, newValue in
            if newValue == nil {
                showOnboarding = false
            }
        }
    }
}
