import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserPair: Hashable {
    let payer: String
    let payee: String
}

enum SettleMethod: String, Codable {
    case cash, upi, bank, other
}

class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []
    @Published var directExpenses: [Expense] = []
    @Published var groupExpenses: [Expense] = []
    @Published var didUpdateExpenses: Bool = false
    @Published var lastSettlement: SettlementResult?

    private var allBalances: [UserPair: Double] = [:]
    private var deletedFriendIds: Set<String> = []

    var currentUser: User? {
        didSet {
            fetchFriends()
            loadDirectExpensesFromFirestore()
        }
    }
    
    private let db = Firestore.firestore()
    
    // MARK: - Sync with Groups
    func syncWithGroups(_ groups: [Group]) {
        let allUsers = Set(groups.flatMap { $0.members })
        let allGroupExpenses = groups.flatMap { $0.expenses }
        let directUsers = Set(directExpenses.flatMap { $0.participants })
        let filteredUsers = allUsers.union(directUsers)
            .filter { !deletedFriendIds.contains($0.id) && $0.id != currentUser?.id }
        DispatchQueue.main.async {
            self.friends = Array(filteredUsers).sorted { $0.name < $1.name }
            self.groupExpenses = allGroupExpenses
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
                if self.deletedFriendIds.contains(friendId) || friendId == currentUser.id {
                    completion(.success(false))
                    return
                }
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
        if deletedFriendIds.contains(friendId) || friendId == currentUser.id {
            completion(.success(false))
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
                    if !self.friends.contains(where: { $0.id == user.id }) && !self.deletedFriendIds.contains(user.id) && user.id != currentUser.id {
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
        let userRef = db.collection("users").document(currentUser.id)
        userRef.getDocument { doc, error in
            let directUsers = Set(self.directExpenses.flatMap { $0.participants })
            guard let doc = doc, let data = doc.data(), let friendIds = data["friends"] as? [String], !friendIds.isEmpty else {
                DispatchQueue.main.async {
                    let filteredUsers = directUsers.filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                    self.friends = Array(filteredUsers).sorted { $0.name < $1.name }
                }
                return
            }
            let filteredFriendIds = friendIds.filter { $0 != currentUser.id && !self.deletedFriendIds.contains($0) }
            if filteredFriendIds.isEmpty {
                DispatchQueue.main.async {
                    let filteredUsers = directUsers.filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                    self.friends = Array(filteredUsers).sorted { $0.name < $1.name }
                }
                return
            }
            self.db.collection("users").whereField(FieldPath.documentID(), in: filteredFriendIds).getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let users = docs.compactMap { doc in
                    let data = doc.data()
                    return User(id: doc.documentID, name: data["name"] as? String ?? "", email: data["email"] as? String)
                }
                let allUsers = Set(users).union(directUsers)
                    .filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                DispatchQueue.main.async {
                    self.friends = Array(allUsers).sorted { $0.name < $1.name }
                }
            }
        }
    }
    
    // --- Direct Expense Persistence ---
    func saveDirectExpensesToFirestore() {
        guard let currentUser else { return }
        let expensesData = directExpenses.map { $0.toDict() }
        db.collection("users").document(currentUser.id).setData([
            "directExpenses": expensesData
        ], merge: true)
    }

    func loadDirectExpensesFromFirestore(completion: @escaping () -> Void = {}) {
        guard let currentUser else { completion(); return }
        db.collection("users").document(currentUser.id).getDocument { doc, error in
            guard let data = doc?.data(), let expensesArr = data["directExpenses"] as? [[String: Any]] else {
                DispatchQueue.main.async { completion() }
                return
            }
            let expenses = expensesArr.compactMap { Expense.fromDict($0) }
            DispatchQueue.main.async {
                self.directExpenses = expenses
                self.refreshFriends()
                self.didUpdateExpenses.toggle()
                completion()
            }
        }
    }

    // --- Calculate net balances between all users (Splitwise logic) ---
    private func calculateAllBalances() {
        var balances: [UserPair: Double] = [:]
        for expense in directExpenses {
            let paidBy = expense.paidBy
            let participants = expense.participants
            let splitAmount = expense.amount / Double(participants.count)
            for user in participants {
                if user.id == paidBy.id { continue }
                let key = UserPair(payer: paidBy.id, payee: user.id)
                balances[key, default: 0.0] += splitAmount
                let reverseKey = UserPair(payer: user.id, payee: paidBy.id)
                balances[reverseKey, default: 0.0] -= splitAmount
            }
        }
        self.allBalances = balances
    }

    // --- Updated balance calculation ---
    func balanceWith(friend: User) -> Double {
        guard let currentUser else { return 0 }
        calculateAllBalances()
        let key = UserPair(payer: currentUser.id, payee: friend.id)
        return allBalances[key, default: 0.0]
    }

    // MARK: - Settle and Clear Expenses
    struct SettlementResult {
        let friend: User
        let amount: Double
        let method: SettleMethod
        let message: String
    }

    func clearExpensesWith(friend: User, method: SettleMethod, note: String? = nil) {
        guard let currentUser else { return }
        directExpenses.removeAll { expense in
            let ids = expense.participants.map { $0.id }
            return ids.contains(currentUser.id) && ids.contains(friend.id)
        }
        saveDirectExpensesToFirestore()
        refreshFriends()
        didUpdateExpenses.toggle()
        lastSettlement = SettlementResult(
            friend: friend,
            amount: abs(balanceWith(friend: friend)),
            method: method,
            message: note ?? "Settled via \(method.rawValue.capitalized)!"
        )
    }

    func isSettledWith(friend: User) -> Bool {
        abs(balanceWith(friend: friend)) < 0.01
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
        deletedFriendIds.insert(friendId)
        DispatchQueue.main.async {
            self.friends.removeAll { $0.id == friendId }
        }
    }

    func refreshFriends() {
        var allUsers = Set<User>()
        allUsers.formUnion(friends)
        allUsers.formUnion(directExpenses.flatMap { $0.participants })
        if let me = currentUser {
            allUsers.insert(me)
        }
        self.friends = Array(allUsers)
            .filter { !deletedFriendIds.contains($0.id) && $0.id != currentUser?.id }
            .sorted { $0.name < $1.name }
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    // --- Sorting ---
    func sortFriendsByOwesYou(_ sort: Bool) {
        if sort {
            // Sort descending by balance (friends who owe you first)
            friends.sort {
                balanceWith(friend: $0) > balanceWith(friend: $1)
            }
        } else {
            // Sort alphabetically
            friends.sort { $0.name.lowercased() < $1.name.lowercased() }
        }
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
        let curUserObj = friends.first(where: { $0.id == currentUser.id }) ?? currentUser
        let friendObj = friends.first(where: { $0.id == friend.id }) ?? friend
        if deletedFriendIds.contains(friendObj.id) || friendObj.id == currentUser.id { return }
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
        var updatedFriends = Set(friends)
        updatedFriends.insert(curUserObj)
        updatedFriends.insert(friendObj)
        friends = Array(updatedFriends)
            .filter { !deletedFriendIds.contains($0.id) && $0.id != currentUser.id }
            .sorted { $0.name < $1.name }
        saveDirectExpensesToFirestore()
        refreshFriends()
        didUpdateExpenses.toggle()
    }

    func editDirectExpense(expense: Expense, to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let currentUser else { return }
        if let idx = directExpenses.firstIndex(where: { $0.id == expense.id }) {
            let curUserObj = friends.first(where: { $0.id == currentUser.id }) ?? currentUser
            let friendObj = friends.first(where: { $0.id == friend.id }) ?? friend
            directExpenses[idx].title = description
            directExpenses[idx].amount = amount
            directExpenses[idx].paidBy = paidByMe ? curUserObj : friendObj
            directExpenses[idx].date = date
            saveDirectExpensesToFirestore()
            refreshFriends()
            didUpdateExpenses.toggle()
        }
    }

    func settleUpWith(friend: User, method: SettleMethod = .other, note: String? = nil) {
        clearExpensesWith(friend: friend, method: method, note: note)
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
