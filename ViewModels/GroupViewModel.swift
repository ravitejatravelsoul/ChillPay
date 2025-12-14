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

    // Firestore integration
    private let db = Firestore.firestore()
    private var groupsListener: ListenerRegistration?
    @Published var isLoadingGroups: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(friendsVM: FriendsViewModel? = nil) {
        self.friendsVM = friendsVM

        // Load local cache first (fast UI)
        self.groups = StorageManager.shared.loadGroups()
        friendsVM?.syncWithGroups(groups)
        updateGlobalCaches()

        // ✅ IMPORTANT: attach listener when currentUser becomes available (not just after 0.1s)
        observeCurrentUserAndListen()
    }

    private func observeCurrentUserAndListen() {
        // If friendsVM exists, observe changes to currentUser and (re)attach listener
        friendsVM?.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                guard let uid = user?.id, !uid.isEmpty else { return }
                self.startListening(forUserId: uid)
            }
            .store(in: &cancellables)

        // Also handle the case where currentUser is already set before this VM is created
        if let uid = friendsVM?.currentUser?.id, !uid.isEmpty {
            startListening(forUserId: uid)
        }
    }

    // MARK: - CRUD
    func addGroup(_ group: Group) {
        groups.append(group)
        logActivity(for: group.id, text: "Created group \(group.name)")
        saveGroupToFirestore(group)
    }

    func updateGroup(_ group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index] = group
        logActivity(for: group.id, text: "Updated group \(group.name)")
        saveGroupToFirestore(groups[index])
    }

    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
        updateGlobalCaches()
        deleteGroupFromFirestore(group)
    }

    func renameGroup(_ group: Group, newName: String) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].name = newName
        logActivity(for: group.id, text: "Renamed group to \(newName)")
        saveGroupToFirestore(groups[index])
    }

    func addMember(_ user: User, to group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        if !groups[index].members.contains(user) {
            groups[index].members.append(user)
            logActivity(for: group.id, text: "Added member \(user.name)")

            NotificationManager.shared.sendPushNotification(
                to: user,
                title: "Added to Group",
                body: "You've been added to group \"\(groups[index].name)\"."
            )

            saveGroupToFirestore(groups[index])
        }
    }

    func removeMember(_ user: User, from group: Group) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }

        var g = groups[index]
        g.expenses.removeAll { exp in
            exp.paidBy.id == user.id || exp.participants.contains(where: { $0.id == user.id })
        }
        g.members.removeAll { $0.id == user.id }
        groups[index] = g

        logActivity(for: group.id, text: "Removed member \(user.name)")

        NotificationManager.shared.sendPushNotification(
            to: user,
            title: "Removed from Group",
            body: "You've been removed from group \"\(groups[index].name)\"."
        )

        saveGroupToFirestore(groups[index])
    }

    // MARK: - Group Expenses (persist + sync)
    func addExpense(_ expense: Expense, to group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }

        groups[idx].expenses.append(expense)
        logActivity(for: group.id, text: "Added expense: \(expense.title)")

        if let me = friendsVM?.currentUser {
            for member in groups[idx].members where member.id != me.id {
                NotificationManager.shared.sendPushNotification(
                    to: member,
                    title: "Group Expense Added",
                    body: "\(me.name) added \"\(expense.title)\" for ₹\(expense.amount) in \"\(group.name)\"."
                )
            }
        }

        // ✅ Persist to Firestore so other devices get it
        saveGroupToFirestore(groups[idx])
    }

    func updateExpense(_ expense: Expense, in group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }),
              let eIdx = groups[idx].expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        groups[idx].expenses[eIdx] = expense
        logActivity(for: group.id, text: "Updated expense: \(expense.title)")

        if let me = friendsVM?.currentUser {
            for member in groups[idx].members where member.id != me.id {
                NotificationManager.shared.sendPushNotification(
                    to: member,
                    title: "Group Expense Edited",
                    body: "\(me.name) edited \"\(expense.title)\" for ₹\(expense.amount) in \"\(group.name)\"."
                )
            }
        }

        // ✅ Persist
        saveGroupToFirestore(groups[idx])
    }

    func deleteExpense(_ expense: Expense, from group: Group) {
        guard let idx = groups.firstIndex(where: { $0.id == group.id }) else { return }

        groups[idx].expenses.removeAll { $0.id == expense.id }
        logActivity(for: group.id, text: "Deleted expense: \(expense.title)")

        if let me = friendsVM?.currentUser {
            for member in groups[idx].members where member.id != me.id {
                NotificationManager.shared.sendPushNotification(
                    to: member,
                    title: "Group Expense Deleted",
                    body: "\(me.name) deleted \"\(expense.title)\" in \"\(group.name)\"."
                )
            }
        }

        // ✅ Persist
        saveGroupToFirestore(groups[idx])
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

    // MARK: - Firestore syncing
    private func startListening(forUserId currentUserId: String) {
        groupsListener?.remove()
        groupsListener = nil

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
                for doc in docs {
                    var data = doc.data()

                    // ✅ Ensure dict has correct id if your parser expects it
                    if data["id"] == nil {
                        data["id"] = doc.documentID
                    }

                    if let g = Group.fromDict(data) {
                        updated.append(g)
                    }
                }

                // Optional: sort by name so list is stable
                updated.sort { $0.name.lowercased() < $1.name.lowercased() }

                DispatchQueue.main.async {
                    self.groups = updated
                    self.isLoadingGroups = false
                }
            }
    }

    /// Persist a group document to Firestore
    private func saveGroupToFirestore(_ group: Group) {
        var data = group.toDict()

        // ✅ Critical: make sure memberIds exists for the query `.whereField("memberIds", arrayContains:)`
        if data["memberIds"] == nil {
            data["memberIds"] = group.members.map { $0.id }
        }

        // ✅ Ensure id exists too (helps parsing)
        if data["id"] == nil {
            data["id"] = group.id
        }

        db.collection("groups").document(group.id).setData(data, merge: true)
    }

    /// Delete a group document from Firestore
    private func deleteGroupFromFirestore(_ group: Group) {
        db.collection("groups").document(group.id).delete()
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
