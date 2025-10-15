import SwiftUI

struct AddDirectExpenseView: View {
    let friend: User
    @ObservedObject var friendsVM: FriendsViewModel
    var expenseToEdit: Expense? = nil

    @Environment(\.presentationMode) var presentationMode
    @State private var amount: String
    @State private var description: String
    @State private var paidBy: User?
    @State private var selectedParticipants: Set<User>
    @State private var date: Date
    @State private var errorMsg: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case amount, description
    }

    init(friend: User, friendsVM: FriendsViewModel, expenseToEdit: Expense? = nil) {
        self.friend = friend
        self.friendsVM = friendsVM
        self.expenseToEdit = expenseToEdit

        let currentUser = FriendsViewModel.shared.currentUser

        _amount = State(initialValue: expenseToEdit != nil ? String(format: "%.2f", expenseToEdit!.amount) : "")
        _description = State(initialValue: expenseToEdit?.title ?? "")
        if let exp = expenseToEdit {
            _paidBy = State(initialValue: exp.paidBy)
            _selectedParticipants = State(initialValue: Set(exp.participants))
            _date = State(initialValue: exp.date)
        } else {
            _paidBy = State(initialValue: currentUser)
            _selectedParticipants = State(initialValue: Set([friend, currentUser].compactMap { $0 }))
            _date = State(initialValue: Date())
        }
    }

    var body: some View {
        ChillTheme.background.ignoresSafeArea()
            .overlay(
                ScrollView {
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
                                    .focused($focusedField, equals: .description)

                                TextField("Amount", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .foregroundColor(.primary)
                                    .focused($focusedField, equals: .amount)

                                // Paid By Picker
                                Text("Who paid?")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Picker(selection: $paidBy, label: Text("")) {
                                    if let currentUser = FriendsViewModel.shared.currentUser {
                                        Text("Me (\(currentUser.name))").tag(Optional(currentUser))
                                    }
                                    Text(friend.name).tag(Optional(friend))
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.vertical, 4)
                                .onTapGesture { dismissKeyboard() }

                                // Date Picker
                                DatePicker("Date", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .accentColor(.green)
                                    .padding(.vertical, 2)
                                    .onTapGesture { dismissKeyboard() }

                                // Participants
                                Text("Participants")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                ParticipantsWrapView(
                                    users: [friend] + [FriendsViewModel.shared.currentUser].compactMap { $0 },
                                    selectedParticipants: $selectedParticipants
                                )
                                .onTapGesture { dismissKeyboard() }

                                if let error = errorMsg {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                        .padding(.top, 2)
                                }

                                // Breakdown
                                if let amountValue = Double(amount), let payer = paidBy, !selectedParticipants.isEmpty {
                                    SplitBreakdownView(
                                        amount: amountValue,
                                        paidBy: payer,
                                        participants: Array(selectedParticipants)
                                    )
                                }

                                Button(action: {
                                    dismissKeyboard()
                                    if let amt = Double(amount), let payer = paidBy {
                                        let participants = selectedParticipants.isEmpty
                                            ? [friend, FriendsViewModel.shared.currentUser].compactMap { $0 }
                                            : Array(selectedParticipants)
                                        if let exp = expenseToEdit {
                                            friendsVM.editDirectExpense(
                                                expense: exp,
                                                to: friend,
                                                amount: amt,
                                                description: description,
                                                paidByMe: payer.id == FriendsViewModel.shared.currentUser?.id,
                                                date: date
                                            )
                                        } else {
                                            friendsVM.addDirectExpense(
                                                to: friend,
                                                amount: amt,
                                                description: description,
                                                paidByMe: payer.id == FriendsViewModel.shared.currentUser?.id,
                                                date: date
                                            )
                                        }
                                        friendsVM.refreshFriends()
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
                    .padding(.bottom, 40)
                }
                .ignoresSafeArea(.keyboard)
                .onTapGesture { dismissKeyboard() }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismissKeyboard()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - SplitBreakdownView

struct SplitBreakdownView: View {
    let amount: Double
    let paidBy: User
    let participants: [User]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Split Details:")
                .font(.subheadline).bold().padding(.top, 2)
            ForEach(participants, id: \.id) { user in
                HStack {
                    if user.id == paidBy.id {
                        Text("\(user.name) paid")
                            .foregroundColor(.green)
                    } else {
                        Text("\(user.name) owes")
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Text("₹\(String(format: "%.2f", amount / Double(participants.count)))")
                        .bold()
                }
                .font(.caption)
            }
        }
        .padding(.top, 4)
        .padding(.horizontal, 4)
    }
}
