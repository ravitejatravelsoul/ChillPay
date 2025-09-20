import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    @State private var showAddExpense = false
    
    var body: some View {
        VStack {
            List {
                ForEach(group.expenses) { expense in
                    VStack(alignment: .leading) {
                        Text(expense.title).font(.headline)
                        Text("Amount: $\(expense.amount, specifier: "%.2f")")
                        Text("Paid by: \(expense.paidBy.name)")
                    }
                }
                .onDelete { indexSet in
                    if let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) {
                        groupVM.groups[groupIndex].expenses.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle(group.name)
            .toolbar {
                Button(action: { showAddExpense.toggle() }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(group: group, groupVM: groupVM)
            }
            
            // Balances
            VStack(alignment: .leading) {
                Text("Balances:")
                    .font(.headline)
                let balances = ExpenseViewModel(groupVM: groupVM).getBalances(for: group)
                ForEach(group.members, id: \.id) { user in
                    Text("\(user.name): $\(balances[user] ?? 0, specifier: "%.2f")")
                }
            }
            .padding()
        }
    }
}
