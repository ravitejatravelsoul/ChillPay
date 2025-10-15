import SwiftUI

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
    @State private var expenseDate: Date
    @State private var errorMsg: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, amount
    }

    init(group: Group, groupVM: GroupViewModel, expenseToEdit: Expense? = nil) {
        self.group = group
        self.groupVM = groupVM
        self.expenseToEdit = expenseToEdit

        let currentUser = FriendsViewModel.shared.currentUser

        _title = State(initialValue: expenseToEdit?.title ?? "")
        if let exp = expenseToEdit {
            _amountString = State(initialValue: String(format: "%.2f", exp.amount))
            _paidBy = State(initialValue: exp.paidBy)
            _selectedParticipants = State(initialValue: Set(exp.participants))
            _category = State(initialValue: exp.category)
            _isRecurring = State(initialValue: exp.isRecurring)
            _expenseDate = State(initialValue: exp.date)
        } else {
            _amountString = State(initialValue: "")
            _paidBy = State(initialValue: currentUser) // Default payer is me
            _selectedParticipants = State(initialValue: Set(group.members)) // Default all participants
            _category = State(initialValue: .other)
            _isRecurring = State(initialValue: false)
            _expenseDate = State(initialValue: Date())
        }
    }

    var body: some View {
        ChillTheme.background.ignoresSafeArea()
            .overlay(
                ScrollView {
                    mainForm
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

    @ViewBuilder
    private var mainForm: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 18) {
                Text(expenseToEdit == nil ? "Add Expense" : "Edit Expense")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.white)
                    ZStack(alignment: .leading) {
                        if title.isEmpty {
                            Text("Enter title")
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 18)
                        }
                        TextField("", text: $title)
                            .textFieldStyle(ChillTextFieldStyle())
                            .focused($focusedField, equals: .title)
                    }

                    // Amount
                    Text("Amount (\(group.currency.symbol))")
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

                    // Paid By
                    Text("Paid By")
                        .font(.headline)
                        .foregroundColor(.white)
                    Picker(selection: $paidBy, label: Text("Select Payer").foregroundColor(.white)) {
                        if let currentUser = FriendsViewModel.shared.currentUser {
                            Text("Me (\(currentUser.name))").tag(Optional(currentUser))
                        }
                        ForEach(group.members) { user in
                            if user.id != FriendsViewModel.shared.currentUser?.id {
                                Text(user.name).tag(Optional(user))
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 2)
                    .onTapGesture { dismissKeyboard() }

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
                    .onTapGesture { dismissKeyboard() }

                    // Date
                    Text("Date Paid")
                        .font(.headline)
                        .foregroundColor(.white)
                    DatePicker("Expense Date", selection: $expenseDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .accentColor(.green)
                        .padding(.vertical, 2)
                        .colorScheme(.dark)
                        .onTapGesture { dismissKeyboard() }

                    // Recurring
                    Toggle(isOn: $isRecurring) {
                        Text("Recurring Expense")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.vertical, 4)
                    .onTapGesture { dismissKeyboard() }

                    // Participants (as chips)
                    Text("Participants")
                        .font(.headline)
                        .foregroundColor(.white)
                    ParticipantsWrapView(users: group.members, selectedParticipants: $selectedParticipants)
                        .onTapGesture { dismissKeyboard() }

                    if let msg = errorMsg {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 2)
                    }

                    // Save Button
                    Button(action: {
                        dismissKeyboard()
                        save()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save")
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
            .padding(.bottom, 16)
        }
        .padding(.bottom, 40)
    }

    private var canSave: Bool {
        guard let _ = Double(amountString), let paidBy = paidBy else { return false }
        // If no participants, fallback to all members
        let participants = selectedParticipants.isEmpty ? Set(group.members) : selectedParticipants
        return !title.trimmingCharacters(in: .whitespaces).isEmpty && !participants.isEmpty && group.members.contains(paidBy)
    }

    private func save() {
        guard let amt = Double(amountString), let payer = paidBy else { return }
        let participants = selectedParticipants.isEmpty ? Array(group.members) : Array(selectedParticipants)
        if !canSave { errorMsg = "Fill all required fields"; return }
        let expense = Expense(
            id: expenseToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amt,
            paidBy: payer,
            participants: participants,
            date: expenseDate,
            groupID: expenseToEdit?.groupID,
            comments: expenseToEdit?.comments ?? [],
            category: category,
            isRecurring: isRecurring
        )
        let expenseVM = ExpenseViewModel(groupVM: groupVM)
        if expenseToEdit != nil {
            expenseVM.updateExpense(expense, in: group)
        } else {
            expenseVM.addExpense(expense, to: group)
            // Uncomment or add your NotificationManager if you have it implemented.
            // NotificationManager.shared.scheduleNotification(
            //     title: "New Expense Added",
            //     body: "\(payer.name) paid \(group.currency.symbol)\(String(format: "%.2f", amt)) for \"\(title)\"",
            //     date: Date().addingTimeInterval(1)
            // )
        }
        presentationMode.wrappedValue.dismiss()
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - ParticipantsWrapView and FlexibleView remain unchanged from your implementation

struct ParticipantsWrapView: View {
    let users: [User]
    @Binding var selectedParticipants: Set<User>
    
    var body: some View {
        FlexibleView(
            data: Array(users),
            spacing: 8,
            alignment: .leading
        ) { user in
            Button(action: {
                if selectedParticipants.contains(user) {
                    selectedParticipants.remove(user)
                } else {
                    selectedParticipants.insert(user)
                }
            }) {
                HStack {
                    AvatarView(user: user)
                        .frame(width: 28, height: 28)
                    Text(user.name)
                        .font(.subheadline)
                        .foregroundColor(selectedParticipants.contains(user) ? .white : .gray)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(selectedParticipants.contains(user) ? Color.green : Color(.systemGray4))
                .cornerRadius(14)
            }
        }
    }
}

struct FlexibleView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(Array(data.enumerated()), id: \.element.id) { (index, item) in
                content(item)
                    .padding(.trailing, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if index == data.count - 1 {
                            width = 0
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if index == data.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { value in
            binding.wrappedValue = value
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
