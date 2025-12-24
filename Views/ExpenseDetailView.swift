import SwiftUI
import UserNotifications

/// Displays all details for a specific expense and allows members to comment,
/// edit, schedule a reminder, and settle up this specific expense if applicable.
struct ExpenseDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    var expense: Expense

    @State private var currentExpense: Expense
    @State private var newComment: String = ""
    @State private var selectedAuthor: User
    @State private var showEdit: Bool = false
    @State private var reminderDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
    @State private var showDatePicker: Bool = false
    @State private var showSettleAlert: Bool = false

    /// Use the currency manager to format amounts for the group currency and the user currency.
    @ObservedObject private var currencyManager = CurrencyManager.shared

    // Remove isSettled from @State; use computed property or model value

    init(groupVM: GroupViewModel, group: Group, expense: Expense) {
        self.groupVM = groupVM
        self.group = group
        self.expense = expense
        _currentExpense = State(initialValue: expense)
        if let first = group.members.first {
            _selectedAuthor = State(initialValue: first)
        } else {
            // FIX: id should be String, not UUID
            _selectedAuthor = State(initialValue: User(id: UUID().uuidString, name: ""))
        }
    }

    var isSettled: Bool {
        // If you want to support 'settled' status, add this to Expense and update accordingly.
        // For now, always return false.
        return false
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Details
                    GroupBox(label: Text("Details").font(.headline)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Title:").bold()
                                Text(currentExpense.title)
                            }
                            HStack {
                                Text("Amount:").bold()
                                // Format the amount using the group's currency for clarity
                                let formattedAmount = currencyManager.format(amount: currentExpense.amount, in: group.currency)
                                Text(formattedAmount)
                            }
                            HStack {
                                Text("Category:").bold()
                                Text(currentExpense.category.displayName)
                            }
                            HStack {
                                Text("Date:").bold()
                                Text(currentExpense.date, style: .date)
                            }
                            HStack {
                                Text("Paid by:").bold()
                                Text(currentExpense.paidBy.name)
                            }
                            HStack(alignment: .top) {
                                Text("Participants:").bold()
                                Text(currentExpense.participants.map { $0.name }.joined(separator: ", "))
                            }
                            if currentExpense.isRecurring {
                                HStack {
                                    Text("Recurring:").bold()
                                    Text("Yes")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Settle Up Button and Details (if not already settled)
                    if !isSettled, let settlementInfo = settlementInfo() {
                        GroupBox(label: Text("Settle Up").font(.headline)) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(settlementInfo, id: \.self) { info in
                                    Text(info)
                                        .font(.body)
                                }
                                Button(action: { showSettleAlert = true }) {
                                    Text("Settle This Expense")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                }
                                .alert(isPresented: $showSettleAlert) {
                                    Alert(
                                        title: Text("Settle Expense"),
                                        message: Text("Are you sure you want to mark this expense as settled?"),
                                        primaryButton: .default(Text("Settle"), action: settleExpense),
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }
                    } else if isSettled {
                        GroupBox(label: Text("Settle Up").font(.headline)) {
                            Text("This expense has been settled.")
                                .foregroundColor(.green)
                        }
                    }

                    // Comments
                    GroupBox(label: Text("Comments").font(.headline)) {
                        if currentExpense.comments.isEmpty {
                            Text("No comments yet.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(currentExpense.comments.sorted(by: { $0.date < $1.date })) { comment in
                                HStack(alignment: .top, spacing: 8) {
                                    AvatarView(user: comment.user)
                                    VStack(alignment: .leading) {
                                        Text(comment.user.name)
                                            .font(.subheadline)
                                            .bold()
                                        Text(comment.text)
                                            .font(.body)
                                        Text(comment.date, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Author", selection: $selectedAuthor) {
                                ForEach(group.members) { user in
                                    Text(user.name).tag(user)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            HStack {
                                TextField("Add a comment", text: $newComment)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: addComment) {
                                    Image(systemName: "paperplane.fill")
                                }
                                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }

                    // Reminder
                    GroupBox(label: Text("Reminder").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            if showDatePicker {
                                DatePicker("Notify me on", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                                Button("Set Reminder") {
                                    scheduleReminder()
                                }
                                .padding(.top, 4)
                            } else {
                                Button("Schedule Reminder") {
                                    withAnimation { showDatePicker = true }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Expense Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEdit = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: deleteExpense) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear(perform: syncExpense)
        .sheet(isPresented: $showEdit) {
            AddExpenseView(group: group, groupVM: groupVM, expenseToEdit: currentExpense)
        }
    }

    private func syncExpense() {
        if let updatedGroup = groupVM.groups.first(where: { $0.id == group.id }),
           let updatedExpense = updatedGroup.expenses.first(where: { $0.id == expense.id }) {
            currentExpense = updatedExpense
            // isSettled = updatedExpense.isSettled // If you add isSettled to Expense, update here.
        }
    }

    private func addComment() {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let evm = ExpenseViewModel(groupVM: groupVM)
        evm.addComment(trimmed, by: selectedAuthor, to: currentExpense, in: group)
        newComment = ""
        syncExpense()
    }

    private func deleteExpense() {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        guard let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        let evm = ExpenseViewModel(groupVM: groupVM)
        evm.deleteExpenses(at: IndexSet(integer: expenseIndex), from: group)
        presentationMode.wrappedValue.dismiss()
    }

    private func scheduleReminder() {
        NotificationManager.shared.requestAuthorizationIfNeeded()
        // Only schedule a local notification for monthly outstanding reminder
        NotificationManager.shared.scheduleMonthlyOutstandingReminder()
        showDatePicker = false
    }

    private func settleExpense() {
        let evm = ExpenseViewModel(groupVM: groupVM)
        evm.settleExpense(currentExpense, in: group)
        // If you support isSettled, update here:
        // currentExpense.isSettled = true
        syncExpense()
    }

    /// Per-expense settlement info: who owes whom for this expense.
    private func settlementInfo() -> [String]? {
        guard currentExpense.participants.count > 1 else { return nil }
        let total = currentExpense.amount
        let count = Double(currentExpense.participants.count)
        let share = total / count
        let payer = currentExpense.paidBy
        var info: [String] = []
        for p in currentExpense.participants where p.id != payer.id {
            // Format each person's share in the group's currency using the currency manager
            let formattedShare = currencyManager.format(amount: share, in: group.currency)
            info.append("\(p.name) owes \(payer.name) \(formattedShare)")
        }
        return info.isEmpty ? nil : info
    }
}
