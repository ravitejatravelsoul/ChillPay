import SwiftUI
import Foundation

// If your models are in a separate module, uncomment this line:
// import ChillPayModels

struct AddDirectExpenseView: View {
    let friend: User
    @ObservedObject var friendsVM: FriendsViewModel
    var expenseToEdit: Expense?

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusedField: Field?

    @State private var title: String
    @State private var amountString: String
    @State private var paidByMe: Bool
    @State private var category: ExpenseCategory
    @State private var isRecurring: Bool
    @State private var expenseDate: Date
    @State private var errorMsg: String?

    enum Field: Hashable {
        case title, amount
    }

    init(friend: User, friendsVM: FriendsViewModel, expenseToEdit: Expense? = nil) {
        self.friend = friend
        self.friendsVM = friendsVM
        self.expenseToEdit = expenseToEdit

        _title = State(initialValue: expenseToEdit?.title ?? "")
        _amountString = State(initialValue: expenseToEdit != nil ? String(format: "%.2f", expenseToEdit!.amount) : "")
        _paidByMe = State(initialValue: {
            if let exp = expenseToEdit,
               let currentUser = friendsVM.currentUser {
                return exp.paidBy.id == currentUser.id
            }
            return true
        }())
        _category = State(initialValue: expenseToEdit?.category ?? .other)
        _isRecurring = State(initialValue: expenseToEdit?.isRecurring ?? false)
        _expenseDate = State(initialValue: expenseToEdit?.date ?? Date())
    }

    var body: some View {
        ChillTheme.background.ignoresSafeArea()
            .overlay(
                ScrollView {
                    formView
                }
                .ignoresSafeArea(.keyboard)
                .onTapGesture { dismissKeyboard() }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissKeyboard()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
    }

    // MARK: - Form
    @ViewBuilder
    private var formView: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 18) {
                Text(expenseToEdit == nil ? "Add Expense" : "Edit Expense")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.white)
                    ZStack(alignment: .leading) {
                        if title.isEmpty {
                            Text("Enter description")
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 18)
                        }
                        TextField("", text: $title)
                            .textFieldStyle(ChillTextFieldStyle())
                            .focused($focusedField, equals: .title)
                    }

                    // Amount
                    Text("Amount")
                        .font(.headline)
                        .foregroundColor(.white)
                    ZStack(alignment: .leading) {
                        if amountString.isEmpty {
                            Text("Enter amount")
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 18)
                        }
                        TextField("", text: $amountString)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(ChillTextFieldStyle())
                            .focused($focusedField, equals: .amount)
                    }

                    // Paid By (segmented look)
                    Text("Who Paid?")
                        .font(.headline)
                        .foregroundColor(.white)
                    Picker("Who Paid?", selection: $paidByMe) {
                        Text("You").tag(true)
                        Text(friend.name).tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.vertical, 4)

                    // Category
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.white)
                    Picker(selection: $category, label: Text("Select Category").foregroundColor(.white)) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            HStack {
                                Text(cat.emoji)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 2)

                    // Date
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.white)
                    DatePicker("Expense Date", selection: $expenseDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .accentColor(.green)
                        .padding(.vertical, 2)
                        .colorScheme(.dark)

                    // Recurring
                    Toggle(isOn: $isRecurring) {
                        Text("Recurring Expense")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.vertical, 4)

                    if let msg = errorMsg {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 2)
                    }

                    // Save Button
                    Button(action: saveExpense) {
                        HStack {
                            Spacer()
                            Text(expenseToEdit == nil ? "Add Expense" : "Save Changes")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(canSave ? Color.green : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(!canSave)
                }
            }
            .padding()
            .background(ChillTheme.card)
            .cornerRadius(28)
            .padding(.horizontal, 20)
            .padding(.top, 32)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Validation
    private var canSave: Bool {
        guard let _ = Double(amountString),
              !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return true
    }

    // MARK: - Save Logic
    private func saveExpense() {
        guard let amt = Double(amountString), amt > 0 else {
            errorMsg = "Please enter a valid amount"
            return
        }

        if let exp = expenseToEdit {
            friendsVM.editDirectExpense(
                expense: exp,
                to: friend,
                amount: amt,
                description: title,
                paidByMe: paidByMe,
                date: expenseDate
            )
        } else {
            friendsVM.addDirectExpense(
                to: friend,
                amount: amt,
                description: title,
                paidByMe: paidByMe,
                date: expenseDate
            )
        }

        friendsVM.refreshFriends()
        presentationMode.wrappedValue.dismiss()
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
