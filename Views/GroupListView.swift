import SwiftUI

struct GroupListView: View {
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel

    @State private var showingAddGroup = false

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Groups")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingAddGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.green)
                            .shadow(color: Color.green.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                    .accessibilityLabel("Add Group")
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 18)

                if groupVM.groups.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.15))
                        Text("No groups yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to create your first group.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            ForEach(groupVM.groups) { group in
                                NavigationLink(destination: GroupDetailView(groupVM: groupVM, friendsVM: friendsVM, group: group)) {
                                    GroupCardView(group: group)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(groupVM: groupVM, friendsVM: friendsVM)
            }
        }
    }
}

struct GroupCardView: View {
    let group: Group

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(group.colorName))
                    .frame(width: 48, height: 48)
                Image(systemName: group.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.28))
                .font(.system(size: 22, weight: .medium))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            Color(.sRGB, white: 0.14, opacity: 1)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.11), radius: 8, x: 0, y: 3)
    }
}
