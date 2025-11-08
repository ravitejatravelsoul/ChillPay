import SwiftUI

struct TabBarButton: View {
    let icon: String
    let tab: MainTab
    @Binding var selectedTab: MainTab
    let user: UserProfile?

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack {
                // For profile tab: show DiceBear avatar if available!
                if tab == .profile, let user = user,
                   !user.avatarSeed.isEmpty, !user.avatarStyle.isEmpty {
                    let avatarUrl = "https://api.dicebear.com/7.x/\(user.avatarStyle)/png?seed=\(user.avatarSeed)"
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(selectedTab == .profile ? Color.green : Color(.systemGray), lineWidth: 2)
                            )
                    } placeholder: {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(Color(.systemGray))
                            )
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(selectedTab == tab ? Color.green : Color(.systemGray))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
