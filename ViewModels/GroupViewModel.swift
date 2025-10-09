import Foundation
import Combine

final class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = [] {
        didSet {
            StorageManager.shared.saveGroups(groups)
            friendsVM?.syncWithGroups(groups)
        }
    }

    weak var friendsVM: FriendsViewModel?

    init(friendsVM: FriendsViewModel? = nil) {
        self.friendsVM = friendsVM
        self.groups = StorageManager.shared.loadGroups()
        friendsVM?.syncWithGroups(groups)
    }

    // MARK: - Group Management

    func addGroup(_ group: Group) {
        groups.append(group)
        logActivity(for: group.id, text: "Created group \(group.name)")
    }

    func updateGroup(_ group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
        logActivity(for: group.id, text: "Updated group \(group.name)")
    }

    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
    }

    func renameGroup(_ group: Group, newName: String) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = newName
        logActivity(for: group.id, text: "Renamed group to \(newName)")
    }

    func addMember(_ user: User, to group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        if !groups[index].members.contains(user) {
            groups[index].members.append(user)
            logActivity(for: group.id, text: "Added member \(user.name)")
        }
    }

    func removeMember(_ user: User, from group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        var g = groups[index]
        g.expenses.removeAll { exp in
            exp.paidBy.id == user.id ||
            exp.participants.contains(where: { $0.id == user.id })
        }
        g.members.removeAll { $0.id == user.id }
        groups[index] = g
        logActivity(for: group.id, text: "Removed member \(user.name)")
    }

    func logActivity(for groupID: String, text: String) {
        guard let idx = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let entry = Activity(id: UUID(), text: text, date: Date())
        groups[idx].activity.append(entry)
    }

    // MARK: - Expense Management

    func addExpense(_ expense: Expense, to group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].expenses.append(expense)
        logActivity(for: group.id, text: "Added expense: \(expense.title)")
    }

    func updateExpense(_ expense: Expense, in group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        if let eIdx = groups[idx].expenses.firstIndex(where: { $0.id == expense.id }) {
            groups[idx].expenses[eIdx] = expense
            logActivity(for: group.id, text: "Updated expense: \(expense.title)")
        }
    }

    func deleteExpense(_ expense: Expense, from group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[idx].expenses.removeAll { $0.id == expense.id }
        logActivity(for: group.id, text: "Deleted expense: \(expense.title)")
    }

    func expenses(for group: Group) -> [Expense] {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return [] }
        return groups[idx].expenses
    }
}
