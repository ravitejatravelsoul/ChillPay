import SwiftUI

struct ContentView: View {
    @StateObject private var friendsVM = FriendsViewModel.shared
    @StateObject private var groupVM = GroupViewModel(friendsVM: FriendsViewModel.shared)

    var body: some View {
        TabView {
            NavigationView {
                FriendsView(friendsVM: friendsVM)
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }

            NavigationView {
                GroupListView(groupVM: groupVM, friendsVM: friendsVM)
            }
            .tabItem {
                Label("Groups", systemImage: "person.3.fill")
            }

            NavigationView {
                ActivitiesView()
                    .environmentObject(groupVM)
            }
            .tabItem {
                Label("Activity", systemImage: "clock.arrow.circlepath")
            }

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(groupVM)
        .environmentObject(friendsVM)
    }
}
