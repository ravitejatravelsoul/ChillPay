import Foundation
import SwiftUI

class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []
    @Published var directExpenses: [Expense] = []
    @Published var groupExpenses: [Expense] = []
    
    /// IMPORTANT: Set this to the logged-in user after login/session restore!
    var currentUser: User?
    
    func syncWithGroups(_ groups: [Group]) {
        let allUsers = Set(groups.flatMap { $0.members })
        let allGroupExpenses = groups.flatMap { $0.expenses }
        DispatchQueue.main.async {
            self.friends = Array(allUsers).sorted { $0.name < $1.name }
            self.groupExpenses = allGroupExpenses
        }
    }
    
    func balanceWith(friend: User) -> Double {
        guard let currentUser = currentUser else { return 0 }
        let direct = allExpensesWith(friend: friend)
        let group = groupExpensesWith(friend: friend)
        var net: Double = 0
        
        // Direct expenses
        for expense in direct {
            if expense.paidBy.id == currentUser.id {
                net += expense.amount / Double(expense.participants.count)
            } else if expense.paidBy.id == friend.id {
                net -= expense.amount / Double(expense.participants.count)
            }
        }
        // Group expenses
        for expense in group {
            if expense.paidBy.id == currentUser.id {
                net += expense.amount / Double(expense.participants.count)
            } else if expense.paidBy.id == friend.id {
                net -= expense.amount / Double(expense.participants.count)
            }
        }
        return net
    }
    
    func groupExpensesWith(friend: User) -> [Expense] {
        guard let currentUser = currentUser else { return [] }
        return groupExpenses.filter {
            $0.groupID != nil &&
            ($0.paidBy.id == friend.id || $0.paidBy.id == currentUser.id) &&
            $0.participants.contains(where: { $0.id == friend.id })
        }
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
        friends.sort {
            balanceWith(friend: $0) > balanceWith(friend: $1)
        }
    }
    
    func addOrInviteFriend(identifier: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if identifier.lowercased().hasSuffix("@mail.com") {
            friends.append(User(id: UUID().uuidString, name: identifier.capitalized, email: identifier))
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
        guard let currentUser = currentUser else { return [] }
        let directExpenseHistory: [ActivityEntry] = directExpenses
            .filter { $0.participants.contains(where: { $0.id == friend.id }) }
            .map { expense in
                let whoPaid = expense.paidBy.id == currentUser.id ? "You" : expense.paidBy.name
                return ActivityEntry(
                    id: expense.id,
                    text: "\(whoPaid) paid \(expense.participants.map { $0.name }.joined(separator: ", ")) ₹\(String(format: "%.2f", expense.amount)) for \(expense.title)",
                    date: expense.date
                )
            }
        // Optionally: Add group expense history here too
        return directExpenseHistory.sorted { $0.date > $1.date }
    }
    
    func allExpensesWith(friend: User) -> [Expense] {
        guard let currentUser = currentUser else { return [] }
        let direct = directExpenses.filter {
            ($0.paidBy.id == friend.id || $0.paidBy.id == currentUser.id) &&
            $0.participants.contains(where: { $0.id == friend.id })
        }
        return direct.sorted { $0.date > $1.date }
    }
    
    func addDirectExpense(to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let currentUser = currentUser else { return }
        let curUserObj = friends.first(where: { $0.id == currentUser.id }) ?? currentUser
        let friendObj = friends.first(where: { $0.id == friend.id }) ?? friend
        let expense = Expense(
            id: UUID(),
            title: description,
            amount: amount,
            paidBy: paidByMe ? curUserObj : friendObj,
            participants: [curUserObj, friendObj],
            date: date,
            groupID: nil
        )
        directExpenses.append(expense)
        // --- Force objectWillChange for immediate UI update in rare edge cases ---
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func editDirectExpense(expense: Expense, to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let currentUser = currentUser else { return }
        if let idx = directExpenses.firstIndex(where: { $0.id == expense.id }) {
            let curUserObj = friends.first(where: { $0.id == currentUser.id }) ?? currentUser
            let friendObj = friends.first(where: { $0.id == friend.id }) ?? friend
            directExpenses[idx].title = description
            directExpenses[idx].amount = amount
            directExpenses[idx].paidBy = paidByMe ? curUserObj : friendObj
            directExpenses[idx].date = date
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func settleUpWith(friend: User) {
        // Implement your settle up logic here, or leave empty for now
        print("Settle up with \(friend.name)")
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
}
