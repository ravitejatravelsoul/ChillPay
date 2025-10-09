import SwiftUI

struct AddDirectExpenseView: View {
    let friend: User
    @ObservedObject var friendsVM: FriendsViewModel
    var expenseToEdit: Expense? = nil

    @Environment(\.presentationMode) var presentationMode
    @State private var amount: String
    @State private var description: String
    @State private var paidByMe: Bool
    @State private var date: Date
    @State private var errorMsg: String?

    init(friend: User, friendsVM: FriendsViewModel, expenseToEdit: Expense? = nil) {
        self.friend = friend
        self.friendsVM = friendsVM
        self.expenseToEdit = expenseToEdit
        _amount = State(initialValue: expenseToEdit != nil ? String(format: "%.2f", expenseToEdit!.amount) : "")
        _description = State(initialValue: expenseToEdit?.title ?? "")
        // --- FIX: Use id comparison and optional chaining for currentUser ---
        let paidByMeInit: Bool
        if let expense = expenseToEdit,
           let currentUser = friendsVM.currentUser {
            paidByMeInit = expense.paidBy.id == currentUser.id
        } else {
            paidByMeInit = true
        }
        _paidByMe = State(initialValue: paidByMeInit)
        _date = State(initialValue: expenseToEdit?.date ?? Date())
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(expenseToEdit == nil ? "Add Expense" : "Edit Expense")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Expense Details")
                            .font(.headline)
                            .foregroundColor(.gray)

                        TextField("Description", text: $description)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .foregroundColor(.primary)

                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .foregroundColor(.primary)

                        Picker("Who paid?", selection: $paidByMe) {
                            Text("You").tag(true)
                            Text(friend.name).tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.vertical, 4)

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(.green)
                            .padding(.vertical, 2)

                        if let error = errorMsg {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.top, 2)
                        }

                        Button(action: {
                            if let amt = Double(amount) {
                                if let exp = expenseToEdit {
                                    friendsVM.editDirectExpense(
                                        expense: exp,
                                        to: friend,
                                        amount: amt,
                                        description: description,
                                        paidByMe: paidByMe,
                                        date: date
                                    )
                                } else {
                                    friendsVM.addDirectExpense(
                                        to: friend,
                                        amount: amt,
                                        description: description,
                                        paidByMe: paidByMe,
                                        date: date
                                    )
                                }
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                errorMsg = "Please enter a valid amount"
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text(expenseToEdit == nil ? "Add Expense" : "Save Changes")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(
                                description.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil
                                ? Color.gray
                                : Color.green
                            )
                            .cornerRadius(14)
                        }
                        .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil)
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(28)
                .padding(.horizontal, 24)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}
