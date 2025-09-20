import SwiftUI

/// Form view used to create a new expense or edit an existing one.  When
/// `expenseToEdit` is non‑`nil` the form is prepopulated and saving will
/// update the existing expense rather than adding a new one.
struct AddExpenseView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    var expenseToEdit: Expense?
    
    @State private var title: String
    @State private var amountString: String
    @State private var paidBy: User?
    @State private var selectedParticipants: Set<User>
    @State private var category: ExpenseCategory
    @State private var isRecurring: Bool
    
    init(group: Group, groupVM: GroupViewModel, expenseToEdit: Expense? = nil) {
        self.group = group
        self.groupVM = groupVM
        self.expenseToEdit = expenseToEdit
        _title = State(initialValue: expenseToEdit?.title ?? "")
        // Convert amount to string for binding to TextField
        if let exp = expenseToEdit {
            _amountString = State(initialValue: String(format: "%.2f", exp.amount))
            _paidBy = State(initialValue: exp.paidBy)
            _selectedParticipants = State(initialValue: Set(exp.participants))
            _category = State(initialValue: exp.category)
            _isRecurring = State(initialValue: exp.isRecurring)
        } else {
            _amountString = State(initialValue: "")
            _paidBy = State(initialValue: nil)
            _selectedParticipants = State(initialValue: Set<User>())
            _category = State(initialValue: .other)
            _isRecurring = State(initialValue: false)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                Section(header: Text("Amount (\(group.currency.symbol))")) {
                    TextField("Enter amount", text: $amountString)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Paid By")) {
                    Picker("Select Payer", selection: $paidBy) {
                        Text("Select").tag(Optional<User>(nil))
                        ForEach(group.members) { user in
                            Text(user.name).tag(Optional(user))
                        }
                    }
                }
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Section(header: Text("Recurring")) {
                    Toggle("Recurring Expense", isOn: $isRecurring)
                }
                Section(header: Text("Participants")) {
                    ForEach(group.members) { user in
                        Button(action: {
                            toggleParticipant(user)
                        }) {
                            HStack {
                                AvatarView(user: user)
                                Text(user.name)
                                Spacer()
                                if selectedParticipants.contains(user) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle(expenseToEdit == nil ? "Add Expense" : "Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    /// Determine whether the form contains valid data.
    private var canSave: Bool {
        guard let _ = Double(amountString), let paidBy = paidBy else { return false }
        return !title.trimmingCharacters(in: .whitespaces).isEmpty && !selectedParticipants.isEmpty && group.members.contains(paidBy)
    }
    
    /// Toggle inclusion of a user in the selected participants set.
    private func toggleParticipant(_ user: User) {
        if selectedParticipants.contains(user) {
            selectedParticipants.remove(user)
        } else {
            selectedParticipants.insert(user)
        }
    }
    
    /// Create or update an expense and persist it via `ExpenseViewModel`.
    private func save() {
        guard let amt = Double(amountString), let payer = paidBy else { return }
        let expense = Expense(
            id: expenseToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amt,
            paidBy: payer,
            participants: Array(selectedParticipants),
            date: Date(),
            category: category,
            isRecurring: isRecurring,
            comments: expenseToEdit?.comments ?? []
        )
        let expenseVM = ExpenseViewModel(groupVM: groupVM)
        if expenseToEdit != nil {
            expenseVM.updateExpense(expense, in: group)
        } else {
            expenseVM.addExpense(expense, to: group)
        }
        presentationMode.wrappedValue.dismiss()
    }
}
