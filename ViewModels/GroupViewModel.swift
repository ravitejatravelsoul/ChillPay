import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit

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

    // MARK: - Export/Invite

    func exportCSV(for group: Group) -> URL? {
        let header = "Title,Amount,PaidBy,Participants,Date,Category\n"
        let rows = group.expenses.map { expense in
            let participants = expense.participants.map { $0.name }.joined(separator: "|")
            return "\"\(expense.title)\",\(expense.amount),\"\(expense.paidBy.name)\",\"\(participants)\",\(expense.date),\(expense.category.rawValue)"
        }
        let csv = header + rows.joined(separator: "\n")
        let filename = "\(group.name)-expenses.csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("CSV Export error: \(error)")
            return nil
        }
    }

    func inviteLink(for group: Group) -> String {
        // Example: You could use your domain and group id, or Firebase Dynamic Links
        // Here, just a placeholder
        return "https://chillpay.app/invite?group=\(group.id)"
    }

    func qrImage(for string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        if let cgimg = context.createCGImage(output.transformed(by: .init(scaleX: 10, y: 10)), from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
}
