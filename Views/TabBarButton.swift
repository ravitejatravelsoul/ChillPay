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
                if tab == .profile, let user = user {
                    // Convert the UserProfile into the lightweight User type so AvatarView can be used
                    let lightweight = User(
                        id: user.uid,
                        name: user.name,
                        email: user.email,
                        avatar: user.avatar,
                        avatarSeed: user.avatarSeed,
                        avatarStyle: user.avatarStyle
                    )
                    AvatarView(user: lightweight)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(selectedTab == .profile ? Color.green : Color(.systemGray), lineWidth: 2)
                        )
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
