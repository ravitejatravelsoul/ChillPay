import Foundation

class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = [] {
        didSet {
            StorageManager.shared.saveGroups(groups)
            friendsVM?.syncWithGroups(groups) // Keeps friends always in sync!
        }
    }

    weak var friendsVM: FriendsViewModel?

    init(friendsVM: FriendsViewModel? = nil) {
        self.friendsVM = friendsVM
        self.groups = StorageManager.shared.loadGroups()
        friendsVM?.syncWithGroups(groups) // Initial sync on load
    }

    /// Append a new group to the list.
    func addGroup(_ group: Group) {
        groups.append(group)
        logActivity(for: group.id, text: "Created group \(group.name)")
    }

    /// Replace an existing group with an updated version.
    func updateGroup(_ group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
    }

    /// Delete a group entirely.
    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
    }

    /// Add a member to a group if they are not already present.
    func addMember(_ user: User, to group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        if !groups[index].members.contains(user) {
            groups[index].members.append(user)
            logActivity(for: group.id, text: "Added member \(user.name)")
        }
    }

    /// Remove a member from a group and drop any expenses that reference them.
    func removeMember(_ user: User, from group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        var g = groups[index]
        // Remove any expense where the user paid or participated
        g.expenses.removeAll { expense in
            expense.paidBy.id == user.id || expense.participants.contains(where: { $0.id == user.id })
        }
        // Remove the user from the members list
        g.members.removeAll { $0.id == user.id }
        groups[index] = g
        logActivity(for: group.id, text: "Removed member \(user.name)")
    }

    /// Update a group’s name.
    func renameGroup(_ group: Group, newName: String) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = newName
        logActivity(for: group.id, text: "Renamed group to \(newName)")
    }

    /// Append an entry to a group's activity feed.
    func logActivity(for groupID: UUID, text: String) {
        guard let idx = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let activityEntry = Activity(id: UUID(), text: text, date: Date())
        groups[idx].activity.append(activityEntry)
    }
}
