import Foundation
import SwiftUI

class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []
    @Published var directExpenses: [Expense] = []
    var currentUser: User = User(id: UUID(), name: "You", email: "me@mail.com") // Replace with real current user

    /// Sync friends with all unique members from all groups.
    func syncWithGroups(_ groups: [Group]) {
        let allUsers = Set(groups.flatMap { $0.members })
        DispatchQueue.main.async {
            self.friends = Array(allUsers).sorted { $0.name < $1.name }
        }
    }

    func balanceWith(friend: User) -> Double {
        let expenses = allExpensesWith(friend: friend)
        var net: Double = 0
        for expense in expenses {
            if expense.paidBy == currentUser {
                net += expense.amount / Double(expense.participants.count)
            } else if expense.paidBy == friend {
                net -= expense.amount / Double(expense.participants.count)
            }
        }
        return net
    }

    func balanceString(_ bal: Double, friend: User) -> String {
        if bal > 0 {
            return "\(friend.name) owes you ₹\(String(format: "%.2f", abs(bal)))"
        } else if bal < 0 {
            return "You owe \(friend.name) ₹\(String(format: "%.2f", abs(bal)))"
        } else {
            return "Settled"
        }
    }

    func balanceColor(_ bal: Double) -> Color {
        if bal > 0 { return .green }
        else if bal < 0 { return .red }
        else { return .secondary }
    }

    func sortByOwesYou(sort: Bool) {
        if sort {
            friends.sort { balanceWith(friend: $0) > balanceWith(friend: $1) }
        } else {
            friends.sort { $0.name < $1.name }
        }
    }

    func addOrInviteFriend(identifier: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if identifier.lowercased().hasSuffix("@mail.com") {
            friends.append(User(id: UUID(), name: identifier.capitalized, email: identifier))
            completion(.success(true))
        } else {
            pendingInvites.append(Invite(id: UUID(), email: identifier))
            completion(.success(false))
        }
    }

    func removeFriend(_ friend: User) {
        friends.removeAll { $0.id == friend.id }
    }

    func refreshFriends() {
        // Add backend sync if needed
    }

    func historyWith(friend: User) -> [ActivityEntry] {
        let directExpenseHistory: [ActivityEntry] = directExpenses
            .filter { $0.participants.contains(friend) }
            .map { expense in
                let whoPaid = expense.paidBy == currentUser ? "You" : expense.paidBy.name
                return ActivityEntry(
                    id: expense.id,
                    text: "\(whoPaid) paid \(expense.participants.map { $0.name }.joined(separator: ", ")) ₹\(String(format: "%.2f", expense.amount)) for \(expense.title)",
                    date: expense.date
                )
            }
        return directExpenseHistory.sorted { $0.date > $1.date }
    }

    func allExpensesWith(friend: User) -> [Expense] {
        let direct = directExpenses.filter { ($0.paidBy == friend || $0.paidBy == currentUser) && $0.participants.contains(friend) }
        // Optionally: Merge with group expenses for richer history
        return direct.sorted { $0.date > $1.date }
    }

    func addDirectExpense(to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        let expense = Expense(
            id: UUID(),
            title: description,
            amount: amount,
            paidBy: paidByMe ? currentUser : friend,
            participants: [currentUser, friend],
            date: date,
            groupID: nil
        )
        directExpenses.append(expense)
    }

    func editDirectExpense(expense: Expense, to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        if let idx = directExpenses.firstIndex(where: { $0.id == expense.id }) {
            directExpenses[idx].title = description
            directExpenses[idx].amount = amount
            directExpenses[idx].paidBy = paidByMe ? currentUser : friend
            directExpenses[idx].date = date
        }
    }

    func settleUpWith(friend: User) {
        // Add your settle up logic here
    }
}

struct Invite: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
}

struct ActivityEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let date: Date
}
