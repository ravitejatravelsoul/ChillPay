import SwiftUI

struct AddDirectExpenseView: View {
    let friend: User
    @ObservedObject var friendsVM: FriendsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var amount = ""
    @State private var description = ""
    @State private var paidByMe = true
    @State private var date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Description", text: $description)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Who paid?", selection: $paidByMe) {
                        Text("You").tag(true)
                        Text(friend.name).tag(false)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Button("Add Expense") {
                    if let amt = Double(amount) {
                        friendsVM.addDirectExpense(
                            to: friend,
                            amount: amt,
                            description: description,
                            paidByMe: paidByMe,
                            date: date
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil)
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
