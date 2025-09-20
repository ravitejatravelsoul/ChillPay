import SwiftUI

struct AddExpenseView: View {
    var group: Group
    @ObservedObject var groupVM: GroupViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var amount = ""
    @State private var paidBy: User?
    @State private var selectedParticipants: Set<User> = []

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)

                Picker("Paid By", selection: $paidBy) {
                    ForEach(group.members) { user in
                        Text(user.name).tag(Optional(user))
                    }
                }

                Section(header: Text("Participants")) {
                    ForEach(group.members) { user in
                        Button(action: {
                            if selectedParticipants.contains(user) {
                                selectedParticipants.remove(user)
                            } else {
                                selectedParticipants.insert(user)
                            }
                        }) {
                            HStack {
                                Text(user.name)
                                Spacer()
                                if selectedParticipants.contains(user) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amt = Double(amount),
                              let paidBy = paidBy,
                              !selectedParticipants.isEmpty else { return }
                        let expense = Expense(
                            id: UUID(),
                            title: title,
                            amount: amt,
                            paidBy: paidBy,
                            participants: Array(selectedParticipants),
                            date: Date()
                        )
                        if let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) {
                            // Correct way: modify local variable then re-assign
                            var updatedGroup = groupVM.groups[groupIndex]
                            updatedGroup.expenses.append(expense)
                            groupVM.groups[groupIndex] = updatedGroup
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
