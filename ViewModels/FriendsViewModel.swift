import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []
    @Published var directExpenses: [Expense] = []
    @Published var groupExpenses: [Expense] = []

    /// Set this to the logged-in user after login/session restore!
    var currentUser: User? {
        didSet { fetchFriends() }
    }
    
    private let db = Firestore.firestore()
    
    // MARK: - Sync with Groups
    func syncWithGroups(_ groups: [Group]) {
        let allUsers = Set(groups.flatMap { $0.members })
        let allGroupExpenses = groups.flatMap { $0.expenses }
        DispatchQueue.main.async {
            self.friends = Array(allUsers).sorted { $0.name < $1.name }
            self.groupExpenses = allGroupExpenses
        }
    }
    
    // MARK: - Add Friend or Send Invite
    func addOrInviteFriend(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(FriendAddError.notLoggedIn))
            return
        }
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let document = snapshot?.documents.first {
                // User exists, add as friend for both users
                let friendId = document.documentID
                self.addFriendship(with: friendId, friendEmail: email) { result in
                    completion(result)
                }
            } else {
                // Not found: send invite
                self.sendInvite(toEmail: email)
                completion(.success(false))
            }
        }
    }

    private func addFriendship(with friendId: String, friendEmail: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(FriendAddError.notLoggedIn))
            return
        }
        let myId = currentUser.id
        let userRef = db.collection("users").document(myId)
        let friendRef = db.collection("users").document(friendId)
        
        // Add each other as friends (bi-directional)
        userRef.updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
        friendRef.updateData([
            "friends": FieldValue.arrayUnion([myId])
        ])
        // Optionally fetch friend's User data for UI update
        friendRef.getDocument { doc, error in
            if let doc = doc, let data = doc.data() {
                let user = User(id: friendId, name: data["name"] as? String ?? friendEmail, email: data["email"] as? String ?? friendEmail)
                DispatchQueue.main.async {
                    if !self.friends.contains(where: { $0.id == user.id }) {
                        self.friends.append(user)
                    }
                }
                completion(.success(true))
            } else {
                completion(.failure(FriendAddError.unknown))
            }
        }
    }

    private func sendInvite(toEmail email: String) {
        db.collection("invites").addDocument(data: [
            "email": email,
            "inviterId": currentUser?.id ?? "",
            "timestamp": FieldValue.serverTimestamp()
        ])
        DispatchQueue.main.async {
            self.pendingInvites.append(Invite(id: UUID(), email: email))
        }
    }
    
    // MARK: - Fetch Friends
    func fetchFriends() {
        guard let currentUser = currentUser else { return }
        let userRef = db.collection("users").document(currentUser.id)
        userRef.getDocument { doc, error in
            guard let doc = doc, let data = doc.data(), let friendIds = data["friends"] as? [String], !friendIds.isEmpty else { return }
            self.db.collection("users").whereField(FieldPath.documentID(), in: friendIds).getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let users = docs.compactMap { doc in
                    let data = doc.data()
                    return User(id: doc.documentID, name: data["name"] as? String ?? "", email: data["email"] as? String)
                }
                DispatchQueue.main.async {
                    self.friends = users.sorted { $0.name < $1.name }
                }
            }
        }
    }

    // MARK: - Balance & Expense Logic (unchanged)
    func balanceWith(friend: User) -> Double {
        guard let currentUser = currentUser else { return 0 }
        let direct = allExpensesWith(friend: friend)
        let group = groupExpensesWith(friend: friend)
        var net: Double = 0
        for expense in direct {
            if expense.paidBy.id == currentUser.id {
                net += expense.amount / Double(expense.participants.count)
            } else if expense.paidBy.id == friend.id {
                net -= expense.amount / Double(expense.participants.count)
            }
        }
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

    func removeFriend(_ friend: User) {
        // Remove from Firestore friend arrays
        guard let currentUser = currentUser else { return }
        let myId = currentUser.id
        let friendId = friend.id
        let userRef = db.collection("users").document(myId)
        let friendRef = db.collection("users").document(friendId)
        userRef.updateData([
            "friends": FieldValue.arrayRemove([friendId])
        ])
        friendRef.updateData([
            "friends": FieldValue.arrayRemove([myId])
        ])
        DispatchQueue.main.async {
            self.friends.removeAll { $0.id == friendId }
        }
    }

    func refreshFriends() {
        fetchFriends()
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

    // MARK: - Types
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

enum FriendAddError: Error {
    case unknown
    case notLoggedIn
}
