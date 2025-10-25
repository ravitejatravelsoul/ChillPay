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
    @Published var didUpdateExpenses: Bool = false

    /// Set this to the logged-in user after login/session restore!
    var currentUser: User? {
        didSet {
            print("[FriendsViewModel] currentUser didSet: \(String(describing: currentUser?.id))")
            fetchFriends()
            loadDirectExpensesFromFirestore()
        }
    }
    
    private let db = Firestore.firestore()
    
    // MARK: - Sync with Groups
    func syncWithGroups(_ groups: [Group]) {
        print("[FriendsViewModel] syncWithGroups called")
        let allUsers = Set(groups.flatMap { $0.members })
        let allGroupExpenses = groups.flatMap { $0.expenses }
        let directUsers = Set(directExpenses.flatMap { $0.participants })
        DispatchQueue.main.async {
            self.friends = Array(allUsers.union(directUsers)).sorted { $0.name < $1.name }
            self.groupExpenses = allGroupExpenses
            print("[FriendsViewModel] syncWithGroups finished - friends count: \(self.friends.count)")
        }
    }
    
    // --- Add Friend or Send Invite ---
    func addOrInviteFriend(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser else {
            completion(.failure(FriendAddError.notLoggedIn))
            return
        }
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let document = snapshot?.documents.first {
                let friendId = document.documentID
                self.addFriendship(with: friendId, friendEmail: email) { result in
                    completion(result)
                }
            } else {
                self.sendInvite(toEmail: email)
                completion(.success(false))
            }
        }
    }

    private func addFriendship(with friendId: String, friendEmail: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser else {
            completion(.failure(FriendAddError.notLoggedIn))
            return
        }
        let myId = currentUser.id
        let userRef = db.collection("users").document(myId)
        let friendRef = db.collection("users").document(friendId)
        userRef.updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
        friendRef.updateData([
            "friends": FieldValue.arrayUnion([myId])
        ])
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
    
    // --- Fetch Friends ---
    func fetchFriends() {
        guard let currentUser else { return }
        print("[FriendsViewModel] fetchFriends called")
        let userRef = db.collection("users").document(currentUser.id)
        userRef.getDocument { doc, error in
            let directUsers = Set(self.directExpenses.flatMap { $0.participants })
            guard let doc = doc, let data = doc.data(), let friendIds = data["friends"] as? [String], !friendIds.isEmpty else {
                DispatchQueue.main.async {
                    self.friends = Array(directUsers).sorted { $0.name < $1.name }
                    print("[FriendsViewModel] fetchFriends finished - friends count: \(self.friends.count)")
                }
                return
            }
            self.db.collection("users").whereField(FieldPath.documentID(), in: friendIds).getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let users = docs.compactMap { doc in
                    let data = doc.data()
                    return User(id: doc.documentID, name: data["name"] as? String ?? "", email: data["email"] as? String)
                }
                let allUsers = Set(users).union(directUsers)
                DispatchQueue.main.async {
                    self.friends = Array(allUsers).sorted { $0.name < $1.name }
                    print("[FriendsViewModel] fetchFriends finished - friends count: \(self.friends.count)")
                }
            }
        }
    }
    
    // --- Direct Expense Persistence ---
    func saveDirectExpensesToFirestore() {
        guard let currentUser else { return }
        print("[FriendsViewModel] saveDirectExpensesToFirestore called - directExpenses count: \(directExpenses.count)")
        let expensesData = directExpenses.map { $0.toDict() }
        db.collection("users").document(currentUser.id).setData([
            "directExpenses": expensesData
        ], merge: true)
    }

    func loadDirectExpensesFromFirestore(completion: @escaping () -> Void = {}) {
        guard let currentUser else { completion(); return }
        print("[FriendsViewModel] loadDirectExpensesFromFirestore called")
        db.collection("users").document(currentUser.id).getDocument { doc, error in
            guard let data = doc?.data(), let expensesArr = data["directExpenses"] as? [[String: Any]] else {
                DispatchQueue.main.async { completion() }
                return
            }
            let expenses = expensesArr.compactMap { Expense.fromDict($0) }
            DispatchQueue.main.async {
                self.directExpenses = expenses
                print("[FriendsViewModel] loadDirectExpensesFromFirestore finished - directExpenses count: \(self.directExpenses.count)")
                self.refreshFriends()
                self.didUpdateExpenses.toggle()
                completion()
            }
        }
    }

    // --- Balance & Expense Logic ---
    func balanceWith(friend: User) -> Double {
        guard let currentUser else { return 0 }
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
        guard let currentUser else { return [] }
        return groupExpenses.filter {
            $0.groupID != nil &&
            ($0.paidBy.id == friend.id || $0.paidBy.id == currentUser.id) &&
            $0.participants.contains(where: { $0.id == friend.id })
        }
    }

    func balanceString(_ bal: Double, friend: User) -> String {
        let epsilon = 0.01
        if bal > epsilon {
            return "\(friend.name) owes you ₹\(String(format: "%.2f", abs(bal)))"
        } else if bal < -epsilon {
            return "You owe \(friend.name) ₹\(String(format: "%.2f", abs(bal)))"
        } else {
            return "Settled"
        }
    }

    func balanceColor(_ bal: Double) -> Color {
        let epsilon = 0.01
        if bal > epsilon { return .green }
        else if bal < -epsilon { return .red }
        else { return .secondary }
    }

    func sortByOwesYou(sort: Bool) {
        friends.sort {
            balanceWith(friend: $0) > balanceWith(friend: $1)
        }
    }

    func removeFriend(_ friend: User) {
        guard let currentUser else { return }
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

    /// Ensures all direct expense participants are present in friends list
    func refreshFriends() {
        print("[FriendsViewModel] refreshFriends called")
        var allUsers = Set<User>()
        allUsers.formUnion(friends)
        allUsers.formUnion(directExpenses.flatMap { $0.participants })
        if let me = currentUser {
            allUsers.insert(me)
        }
        self.friends = Array(allUsers).sorted { $0.name < $1.name }
        print("[FriendsViewModel] refreshFriends finished - friends count: \(self.friends.count)")
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func historyWith(friend: User) -> [ActivityEntry] {
        guard let currentUser else { return [] }
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
        guard let currentUser else { return [] }
        let direct = directExpenses.filter {
            ($0.paidBy.id == friend.id || $0.paidBy.id == currentUser.id) &&
            $0.participants.contains(where: { $0.id == friend.id })
        }
        return direct.sorted { $0.date > $1.date }
    }

    func addDirectExpense(to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let currentUser else { return }
        print("[FriendsViewModel] addDirectExpense called for friendId: \(friend.id) amount: \(amount)")
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
        print("[FriendsViewModel] addDirectExpense appended - directExpenses count: \(directExpenses.count)")
        var updatedFriends = Set(friends)
        updatedFriends.insert(curUserObj)
        updatedFriends.insert(friendObj)
        friends = Array(updatedFriends).sorted { $0.name < $1.name }
        saveDirectExpensesToFirestore()
        refreshFriends()
        didUpdateExpenses.toggle()
        print("[FriendsViewModel] addDirectExpense finished, didUpdateExpenses toggled")
    }

    func editDirectExpense(expense: Expense, to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let currentUser else { return }
        print("[FriendsViewModel] editDirectExpense called for expenseId: \(expense.id) friendId: \(friend.id) amount: \(amount)")
        if let idx = directExpenses.firstIndex(where: { $0.id == expense.id }) {
            let curUserObj = friends.first(where: { $0.id == currentUser.id }) ?? currentUser
            let friendObj = friends.first(where: { $0.id == friend.id }) ?? friend
            directExpenses[idx].title = description
            directExpenses[idx].amount = amount
            directExpenses[idx].paidBy = paidByMe ? curUserObj : friendObj
            directExpenses[idx].date = date
            print("[FriendsViewModel] editDirectExpense updated expense at idx: \(idx)")
            saveDirectExpensesToFirestore()
            refreshFriends()
            didUpdateExpenses.toggle()
            print("[FriendsViewModel] editDirectExpense finished, didUpdateExpenses toggled")
        }
    }

    func settleUpWith(friend: User) {
        print("[FriendsViewModel] settleUpWith called for friendId: \(friend.id)")
        // Implement logic to remove expenses or mark as settled if needed, then save to Firestore
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
