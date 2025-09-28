import SwiftUI

struct GroupListView: View {
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel

    @State private var showAddGroup = false
    @State private var editingGroup: Group?

    var body: some View {
        List {
            ForEach(groupVM.groups) { group in
                NavigationLink(destination: ExpenseListView(groupVM: groupVM, group: group)) {
                    HStack(spacing: 8) {
                        Image(systemName: group.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(color(for: group.colorName))
                        // Display up to three member avatars
                        ForEach(Array(group.members.prefix(3)), id: \.id) { member in
                            AvatarView(user: member)
                        }
                        Text(group.name)
                            .font(.headline)
                            .padding(.leading, group.members.isEmpty ? 0 : 4)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        groupVM.deleteGroup(group)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        editingGroup = group
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddGroup.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupView(groupVM: groupVM, friendsVM: friendsVM) // <-- Fixed: Now passing friendsVM
        }
        .sheet(item: $editingGroup) { group in
            EditGroupView(group: group, groupVM: groupVM, friendsVM: friendsVM)
        }
    }

    // Utility function to map color names to actual SwiftUI colors
    private func color(for colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .gray
        }
    }
}
