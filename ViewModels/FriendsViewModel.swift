import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Helper types
struct UserPair: Hashable {
    let payer: String
    let payee: String
}

enum SettleMethod: String, Codable {
    case cash, upi, bank, other
}

// MARK: - ViewModel
final class FriendsViewModel: ObservableObject {
    static let shared = FriendsViewModel()

    // Published properties that trigger view refreshes
    @Published var friends: [User] = []
    @Published var pendingInvites: [Invite] = []
    @Published var directExpenses: [Expense] = [] {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    @Published var groupExpenses: [Expense] = [] {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    @Published var didUpdateExpenses: Bool = false
    @Published var lastSettlement: SettlementResult?
    @Published var currentUser: User? {
        didSet {
            print("DEBUG: [FriendsVM] currentUser didSet:", String(describing: currentUser))
            fetchFriends()
            loadDirectExpensesFromFirestore()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private var allBalances: [UserPair: Double] = [:]
    private var deletedFriendIds: Set<String> = []
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
            self.objectWillChange.send()
        }
    }

    // MARK: - Add Friend or Send Invite
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
                self.addFriendship(with: friendId, friendEmail: email, completion: completion)
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

        userRef.updateData(["friends": FieldValue.arrayUnion([friendId])])
        friendRef.updateData(["friends": FieldValue.arrayUnion([myId])])

        friendRef.getDocument { doc, _ in
            if let doc = doc, let data = doc.data() {
                let user = User(id: friendId,
                                name: data["name"] as? String ?? friendEmail,
                                email: data["email"] as? String ?? friendEmail)
                DispatchQueue.main.async {
                    if !self.friends.contains(where: { $0.id == user.id }) &&
                        !self.deletedFriendIds.contains(user.id) &&
                        user.id != currentUser.id {
                        self.friends.append(user)
                        self.objectWillChange.send()
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
            self.objectWillChange.send()
        }
    }

    // MARK: - Fetch Friends
    func fetchFriends() {
        guard let currentUser else { return }
        let userRef = db.collection("users").document(currentUser.id)
        userRef.getDocument { doc, _ in
            let directUsers = Set(self.directExpenses.flatMap { $0.participants })
            guard let doc = doc,
                  let data = doc.data(),
                  let friendIds = data["friends"] as? [String],
                  !friendIds.isEmpty else {
                DispatchQueue.main.async {
                    let filtered = directUsers.filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                    self.friends = Array(filtered).sorted { $0.name < $1.name }
                    self.objectWillChange.send()
                }
                return
            }

            let validIds = friendIds.filter { $0 != currentUser.id && !self.deletedFriendIds.contains($0) }
            if validIds.isEmpty {
                DispatchQueue.main.async {
                    let filtered = directUsers.filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                    self.friends = Array(filtered).sorted { $0.name < $1.name }
                    self.objectWillChange.send()
                }
                return
            }

            self.db.collection("users").whereField(FieldPath.documentID(), in: validIds).getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let users = docs.map {
                    let d = $0.data()
                    return User(id: $0.documentID,
                                name: d["name"] as? String ?? "",
                                email: d["email"] as? String)
                }
                let combined = Set(users).union(directUsers)
                    .filter { $0.id != currentUser.id && !self.deletedFriendIds.contains($0.id) }
                DispatchQueue.main.async {
                    self.friends = Array(combined).sorted { $0.name < $1.name }
                    self.objectWillChange.send()
                }
            }
        }
    }

    // MARK: - Direct Expense Persistence
    func saveDirectExpensesToFirestore() {
        guard let currentUser else { return }
        let data = directExpenses.map { $0.toDict() }
        db.collection("users").document(currentUser.id)
            .setData(["directExpenses": data], merge: true)
    }

    func loadDirectExpensesFromFirestore(completion: @escaping () -> Void = {}) {
        guard let currentUser else { completion(); return }
        db.collection("users").document(currentUser.id).getDocument { doc, _ in
            guard let data = doc?.data(),
                  let arr = data["directExpenses"] as? [[String: Any]] else {
                DispatchQueue.main.async { completion() }
                return
            }
            let expenses = arr.compactMap { Expense.fromDict($0) }
            DispatchQueue.main.async {
                self.directExpenses = expenses
                self.didUpdateExpenses.toggle()
                self.objectWillChange.send()
                completion()
            }
        }
    }

    // MARK: - Balance calculation
    private func calculateAllBalances() {
        var balances: [UserPair: Double] = [:]
        for expense in directExpenses {
            let paidBy = expense.paidBy
            let participants = expense.participants
            let share = expense.amount / Double(participants.count)
            for user in participants where user.id != paidBy.id {
                balances[UserPair(payer: paidBy.id, payee: user.id), default: 0.0] += share
                balances[UserPair(payer: user.id, payee: paidBy.id), default: 0.0] -= share
            }
        }
        allBalances = balances
    }

    func balanceWith(friend: User) -> Double {
        guard let me = currentUser else { return 0 }
        calculateAllBalances()
        return allBalances[UserPair(payer: me.id, payee: friend.id), default: 0.0]
    }

    // MARK: - Settlement / Clear Expenses
    struct SettlementResult {
        let friend: User
        let amount: Double
        let method: SettleMethod
        let message: String
    }

    func clearExpensesWith(friend: User, method: SettleMethod, note: String? = nil) {
        guard let me = currentUser else { return }
        directExpenses.removeAll { exp in
            let ids = exp.participants.map { $0.id }
            return ids.contains(me.id) && ids.contains(friend.id)
        }
        didUpdateExpenses.toggle()
        saveDirectExpensesToFirestore()
        refreshFriends()
        lastSettlement = SettlementResult(
            friend: friend,
            amount: abs(balanceWith(friend: friend)),
            method: method,
            message: note ?? "Settled via \(method.rawValue.capitalized)!"
        )
        objectWillChange.send()
    }

    func isSettledWith(friend: User) -> Bool {
        abs(balanceWith(friend: friend)) < 0.01
    }

    func removeFriend(_ friend: User) {
        guard let me = currentUser else { return }
        let myId = me.id
        let fid = friend.id
        db.collection("users").document(myId)
            .updateData(["friends": FieldValue.arrayRemove([fid])])
        db.collection("users").document(fid)
            .updateData(["friends": FieldValue.arrayRemove([myId])])
        deletedFriendIds.insert(fid)
        DispatchQueue.main.async {
            self.friends.removeAll { $0.id == fid }
            self.objectWillChange.send()
        }
    }

    // MARK: - Refresh
    func refreshFriends() {
        var allUsers = Set<User>()
        allUsers.formUnion(friends)
        allUsers.formUnion(directExpenses.flatMap { $0.participants })
        if let me = currentUser { allUsers.insert(me) }

        friends = Array(allUsers)
            .filter { !deletedFriendIds.contains($0.id) && $0.id != currentUser?.id }
            .sorted { $0.name < $1.name }

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Sorting
    func sortFriendsByOwesYou(_ sort: Bool) {
        if sort {
            friends.sort { balanceWith(friend: $0) > balanceWith(friend: $1) }
        } else {
            friends.sort { $0.name.lowercased() < $1.name.lowercased() }
        }
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - History
    func historyWith(friend: User) -> [ActivityEntry] {
        guard let me = currentUser else { return [] }
        let entries: [ActivityEntry] = directExpenses
            .filter { $0.participants.contains(where: { $0.id == friend.id }) }
            .map {
                let who = $0.paidBy.id == me.id ? "You" : $0.paidBy.name
                return ActivityEntry(id: $0.id,
                                     text: "\(who) paid \($0.participants.map { $0.name }.joined(separator: ", ")) ₹\(String(format: "%.2f", $0.amount)) for \($0.title)",
                                     date: $0.date)
            }
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: - Aggregate direct/group expenses for dashboard/analytics
    func allExpensesWith(friend: User) -> [Expense] {
        guard let me = currentUser else { return [] }
        let direct = directExpenses.filter {
            ($0.paidBy.id == friend.id || $0.paidBy.id == me.id) &&
            $0.participants.contains(where: { $0.id == friend.id })
        }
        let group = groupExpenses.filter {
            $0.participants.contains(where: { $0.id == friend.id })
        }
        return (direct + group).sorted { $0.date > $1.date }
    }

    // MARK: - Add/Edit Expense
    func addDirectExpense(to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let me = currentUser else { return }
        let meObj = friends.first(where: { $0.id == me.id }) ?? me
        let frObj = friends.first(where: { $0.id == friend.id }) ?? friend

        if deletedFriendIds.contains(frObj.id) || frObj.id == me.id { return }

        let expense = Expense(
            id: UUID(),
            title: description,
            amount: amount,
            paidBy: paidByMe ? meObj : frObj,
            participants: [meObj, frObj],
            date: date,
            groupID: nil
        )

        directExpenses.append(expense)
        didUpdateExpenses.toggle()
        saveDirectExpensesToFirestore()
        refreshFriends()
        objectWillChange.send()
    }

    func editDirectExpense(expense: Expense, to friend: User, amount: Double, description: String, paidByMe: Bool, date: Date) {
        guard let me = currentUser else { return }
        if let idx = directExpenses.firstIndex(where: { $0.id == expense.id }) {
            let meObj = friends.first(where: { $0.id == me.id }) ?? me
            let frObj = friends.first(where: { $0.id == friend.id }) ?? friend

            directExpenses[idx].title = description
            directExpenses[idx].amount = amount
            directExpenses[idx].paidBy = paidByMe ? meObj : frObj
            directExpenses[idx].date = date

            didUpdateExpenses.toggle()
            saveDirectExpensesToFirestore()
            refreshFriends()
            objectWillChange.send()
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

// MARK: - Error
enum FriendAddError: Error {
    case unknown
    case notLoggedIn
}
