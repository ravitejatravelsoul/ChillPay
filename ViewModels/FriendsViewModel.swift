import Foundation
import SwiftUI

class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []

    /// Sync friends with all unique members from all groups.
    func syncWithGroups(_ groups: [Group]) {
        let allUsers = Set(groups.flatMap { $0.members })
        // Fix: Publish on main queue to avoid SwiftUI warning
        DispatchQueue.main.async {
            self.friends = Array(allUsers).sorted { $0.name < $1.name }
        }
    }

    // Mock balances for display purposes
    func balanceWith(friend: User) -> Double {
        // Replace with your actual logic
        return Double.random(in: -200...300)
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
        // Mock: If email ends with @mail.com, add; else invite
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
        // Mock history
        return [
            ActivityEntry(id: UUID(), text: "You paid \(friend.name) ₹200", date: Date().addingTimeInterval(-86400)),
            ActivityEntry(id: UUID(), text: "\(friend.name) paid you ₹100", date: Date().addingTimeInterval(-172800))
        ]
    }

    func addDirectExpense(to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        // Add to history, update balances etc.
    }

    func settleUpWith(friend: User) {
        // Logic to settle up
    }
}

// Basic models (do NOT redeclare User here!)
struct Invite: Identifiable {
    let id: UUID
    let email: String
}

struct ActivityEntry: Identifiable {
    let id: UUID
    let text: String
    let date: Date
}
