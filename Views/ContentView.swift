import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var showAddSheet = false

    @StateObject private var friendsVM = FriendsViewModel.shared
    @StateObject private var groupVM = GroupViewModel(friendsVM: FriendsViewModel.shared)

    // Main content as a computed property (with @ViewBuilder)
    @ViewBuilder
    var mainContent: some View {
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
                CustomTabBar(selectedTab: $selectedTab, showAddSheet: $showAddSheet)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(groupVM)
        .environmentObject(friendsVM)
        .sheet(isPresented: $showAddSheet) {
            AddGroupView(groupVM: groupVM, friendsVM: friendsVM)
        }
    }
}
