import SwiftUI

/// Presents a list of all groups the user has created.  Each row shows the
/// group name along with a few member avatars.  Users can swipe to edit or
/// delete a group.  A button in the toolbar opens the `AddGroupView` to
/// create a new group.
struct GroupListView: View {
    @ObservedObject var groupVM: GroupViewModel
    
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
            AddGroupView(groupVM: groupVM)
        }
        .sheet(item: $editingGroup) { group in
            EditGroupView(group: group, groupVM: groupVM)
        }
    }
}
