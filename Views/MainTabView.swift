import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }

            GroupsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }

            ActivitiesView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Activities")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}
