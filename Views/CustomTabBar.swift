import SwiftUI

enum MainTab: Int, CaseIterable {
    case home, friends, groups, activity, profile
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @Binding var showAddSheet: Bool
    let user: UserProfile?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: -2)
                .frame(height: 72)
                .padding(.horizontal, 0)

            HStack(spacing: 0) {
                TabBarButton(icon: "house.fill", tab: .home, selectedTab: $selectedTab, user: nil)
                TabBarButton(icon: "person.2.fill", tab: .friends, selectedTab: $selectedTab, user: nil)
                TabBarButton(icon: "person.3.fill", tab: .groups, selectedTab: $selectedTab, user: nil)
                TabBarButton(icon: "clock.arrow.circlepath", tab: .activity, selectedTab: $selectedTab, user: nil)
                // For .profile, supply the current user!
                TabBarButton(icon: "person.circle", tab: .profile, selectedTab: $selectedTab, user: user)
            }
            .padding(.horizontal, 32)
            .frame(height: 72)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 0)
        .background(Color.clear)
    }
}
