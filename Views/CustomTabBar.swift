import SwiftUI

enum MainTab: Int, CaseIterable {
    case home, friends, groups, activity, profile // Changed from .settings to .profile
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @Binding var showAddSheet: Bool // You can remove this binding if not used elsewhere

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
                TabBarButton(icon: "house.fill", tab: .home, selectedTab: $selectedTab)
                TabBarButton(icon: "person.2.fill", tab: .friends, selectedTab: $selectedTab)
                TabBarButton(icon: "person.3.fill", tab: .groups, selectedTab: $selectedTab)
                TabBarButton(icon: "clock.arrow.circlepath", tab: .activity, selectedTab: $selectedTab)
                TabBarButton(icon: "person.circle", tab: .profile, selectedTab: $selectedTab) // Changed icon and tab
            }
            .padding(.horizontal, 32)
            .frame(height: 72)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 0)
        .background(Color.clear)
    }
}

struct TabBarButton: View {
    let icon: String
    let tab: MainTab
    @Binding var selectedTab: MainTab

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(selectedTab == tab ? Color.green : Color(.systemGray))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
