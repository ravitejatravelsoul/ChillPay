import SwiftUI
import UserNotifications

/// Displays all details for a specific expense and allows members to comment,
/// edit or schedule a reminder for it.
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
    
    init(groupVM: GroupViewModel, group: Group, expense: Expense) {
        self.groupVM = groupVM
        self.group = group
        self.expense = expense
        _currentExpense = State(initialValue: expense)
        if let first = group.members.first {
            _selectedAuthor = State(initialValue: first)
        } else {
            _selectedAuthor = State(initialValue: User(id: UUID(), name: ""))
        }
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
                                let amountString = String(format: "%.2f", currentExpense.amount)
                                Text("\(group.currency.symbol)\(amountString)")
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
        let title = "Expense Reminder: \(currentExpense.title)"
        let amountString = String(format: "%.2f", currentExpense.amount)
        let body = "Don't forget about \(currentExpense.title) for \(group.currency.symbol)\(amountString)."
        NotificationManager.shared.scheduleNotification(title: title, body: body, date: reminderDate)
        showDatePicker = false
    }
}
