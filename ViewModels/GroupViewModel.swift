import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import FirebaseFirestore

final class GroupViewModel: ObservableObject {

    @Published var groups: [Group] = [] {
        didSet {
            StorageManager.shared.saveGroups(groups)
            friendsVM?.syncWithGroups(groups)
            updateGlobalCaches()
        }
    }

    // Global reactive caches (for Dashboard & Analytics)
    @Published var globalExpenseCount: Int = 0
    @Published var globalExpenseSum: Double = 0
    @Published var globalActivityCount: Int = 0
    @Published var globalActivity: [Activity] = []

    weak var friendsVM: FriendsViewModel?

    private let db = Firestore.firestore()
    private var groupsListener: ListenerRegistration?
    private var expenseListeners: [String: ListenerRegistration] = [:] // groupId -> listener

    @Published var isLoadingGroups: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init(friendsVM: FriendsViewModel? = nil) {
        self.friendsVM = friendsVM

        // local cache first
        self.groups = StorageManager.shared.loadGroups()
        friendsVM?.syncWithGroups(groups)
        updateGlobalCaches()

        observeCurrentUserAndListen()
    }

    deinit {
        groupsListener?.remove()
        expenseListeners.values.forEach { $0.remove() }
        expenseListeners.removeAll()
    }

    private func observeCurrentUserAndListen() {
        friendsVM?.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                guard let uid = user?.id, !uid.isEmpty else { return }
                self.startListening(forUserId: uid)
            }
            .store(in: &cancellables)

        if let uid = friendsVM?.currentUser?.id, !uid.isEmpty {
            startListening(forUserId: uid)
        }
    }

    // MARK: - CRUD (Group Meta)
    func addGroup(_ group: Group) {
        groups.append(group)
        logActivity(for: group.id, text: "Created group \(group.name)")
        saveGroupMetaToFirestore(group)
        // expenses will be written when you add them (subcollection)
    }

    func updateGroup(_ group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
        logActivity(for: group.id, text: "Updated group \(group.name)")
        saveGroupMetaToFirestore(groups[index])
    }

    func deleteGroup(_ group: Group) {
        // remove local
        groups.removeAll { $0.id == group.id }
        updateGlobalCaches()

        // remove listeners
        expenseListeners[group.id]?.remove()
        expenseListeners[group.id] = nil

        // delete from Firestore
        deleteGroupFromFirestore(group)
    }

    func renameGroup(_ group: Group, newName: String) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = newName
        logActivity(for: group.id, text: "Renamed group to \(newName)")
        saveGroupMetaToFirestore(groups[index])
    }

    func addMember(_ user: User, to group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        if !groups[index].members.contains(user) {
            groups[index].members.append(user)
            logActivity(for: group.id, text: "Added member \(user.name)")
            saveGroupMetaToFirestore(groups[index])
        }
    }

    func removeMember(_ user: User, from group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }

        var g = groups[index]
        g.members.removeAll { $0.id == user.id }
        // NOTE: We do NOT auto-delete their past expenses here — you can decide policy later.
        groups[index] = g

        logActivity(for: group.id, text: "Removed member \(user.name)")
        saveGroupMetaToFirestore(groups[index])
    }

    // MARK: - ✅ Group Expenses (FireStore Subcollection)
    func addExpense(_ expense: Expense, to group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }

        // update local immediately (fast UI)
        groups[idx].expenses.append(expense)
        logActivity(for: group.id, text: "Added expense: \(expense.title)")

        // write to Firestore subcollection (this triggers your Cloud Function!)
        saveGroupExpenseToFirestore(expense, groupId: group.id)
    }

    func updateExpense(_ expense: Expense, in group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }
        guard let eIdx = groups[idx].expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        groups[idx].expenses[eIdx] = expense
        logActivity(for: group.id, text: "Updated expense: \(expense.title)")

        saveGroupExpenseToFirestore(expense, groupId: group.id)
    }

    func deleteExpense(_ expense: Expense, from group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }

        groups[idx].expenses.removeAll { $0.id == expense.id }
        logActivity(for: group.id, text: "Deleted expense: \(expense.title)")

        deleteGroupExpenseFromFirestore(expenseId: expense.id.uuidString, groupId: group.id)
    }

    // MARK: - Activity & metrics
    func logActivity(for groupID: String, text: String) {
        guard let idx = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let entry = Activity(id: UUID(), text: text, date: Date())
        groups[idx].activity.append(entry)
        updateGlobalCaches()
    }

    func expenses(for group: Group) -> [Expense] {
        groups.first(where: { $0.id == group.id })?.expenses ?? []
    }

    private func updateGlobalCaches() {
        let allExpenses = groups.flatMap { $0.expenses }
        let expenseCount = allExpenses.count
        let totalSum = allExpenses.reduce(0) { $0 + $1.amount }
        let allActivities = groups.flatMap { $0.activity }.sorted { $0.date > $1.date }

        DispatchQueue.main.async {
            self.globalExpenseCount = expenseCount
            self.globalExpenseSum = totalSum
            self.globalActivityCount = allActivities.count
            self.globalActivity = allActivities
        }
    }

    // MARK: - ✅ Firestore syncing (Groups + Expenses)
    private func startListening(forUserId currentUserId: String) {
        groupsListener?.remove()
        groupsListener = nil

        // remove old expense listeners
        expenseListeners.values.forEach { $0.remove() }
        expenseListeners.removeAll()

        isLoadingGroups = true

        groupsListener = db.collection("groups")
            .whereField("memberIds", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("❌ Error listening for groups: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.isLoadingGroups = false }
                    return
                }

                guard let docs = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.groups = []
                        self.isLoadingGroups = false
                    }
                    return
                }

                var updated: [Group] = []
                let groupIds = docs.map { $0.documentID }

                for doc in docs {
                    var data = doc.data()
                    if data["id"] == nil { data["id"] = doc.documentID }

                    if let g = Group.fromDict(data) {
                        // IMPORTANT: expenses will be loaded from subcollection listener
                        var group = g
                        group.expenses = self.groups.first(where: { $0.id == group.id })?.expenses ?? []
                        updated.append(group)

                        // attach (or reattach) expense listener
                        self.attachExpenseListener(groupId: group.id)
                    }
                }

                // remove listeners for groups no longer present
                for (gid, listener) in self.expenseListeners {
                    if !groupIds.contains(gid) {
                        listener.remove()
                        self.expenseListeners[gid] = nil
                    }
                }

                updated.sort { $0.name.lowercased() < $1.name.lowercased() }

                DispatchQueue.main.async {
                    self.groups = updated
                    self.isLoadingGroups = false
                }
            }
    }

    private func attachExpenseListener(groupId: String) {
        // already listening
        if expenseListeners[groupId] != nil { return }

        let listener = db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    print("❌ Error listening expenses for group \(groupId): \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                var expenses: [Expense] = []
                for doc in docs {
                    var data = doc.data()
                    if data["id"] == nil { data["id"] = doc.documentID }
                    if let exp = Expense.fromDict(data) {
                        expenses.append(exp)
                    }
                }

                expenses.sort { $0.date > $1.date }

                DispatchQueue.main.async {
                    if let idx = self.groups.firstIndex(where: { $0.id == groupId }) {
                        self.groups[idx].expenses = expenses
                        self.friendsVM?.syncWithGroups(self.groups)
                        self.updateGlobalCaches()
                    }
                }
            }

        expenseListeners[groupId] = listener
    }

    // MARK: - ✅ Firestore writes
    private func saveGroupMetaToFirestore(_ group: Group) {
        var data = group.toDict()

        // Critical for query `.whereField("memberIds", arrayContains:)`
        data["memberIds"] = group.members.map { $0.id }

        // Ensure id exists for parsing
        data["id"] = group.id

        // IMPORTANT: do not rely on embedding huge expenses array.
        // If your Group.toDict includes expenses, you can strip it:
        data["expenses"] = nil

        db.collection("groups").document(group.id).setData(data, merge: true)
    }

    private func saveGroupExpenseToFirestore(_ expense: Expense, groupId: String) {
        var data = expense.toDict()

        // Cloud function depends on this:
        data["participantIds"] = expense.participants.map { $0.id }

        // Identify sender so function can avoid notifying sender
        if let senderId = friendsVM?.currentUser?.id {
            data["senderUserId"] = senderId
        }

        // Keep id consistent
        data["id"] = expense.id.uuidString

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .document(expense.id.uuidString)
            .setData(data, merge: true)
    }

    private func deleteGroupExpenseFromFirestore(expenseId: String, groupId: String) {
        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .document(expenseId)
            .delete()
    }

    private func deleteGroupFromFirestore(_ group: Group) {
        db.collection("groups").document(group.id).delete()
        // NOTE: subcollection docs are not auto-deleted by Firestore.
        // You can add a cleanup function later if needed.
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
