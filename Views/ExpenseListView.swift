import SwiftUI

/// Shows all expenses for a given group, allows adding new expenses,
/// editing existing ones, deleting them, and displays balances and settlements.
struct ExpenseListView: View {
    @ObservedObject var groupVM: GroupViewModel
    @State var group: Group
    
    @State private var showAddExpense = false
    @State private var editingExpense: Expense?
    @State private var selectedExpense: Expense?
    @State private var showSummary = false
    
    var body: some View {
        VStack {
            // Expenses list
            List {
                ForEach(group.expenses) { expense in
                    HStack(alignment: .top, spacing: 8) {
                        AvatarView(user: expense.paidBy)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.title)
                                .font(.headline)
                            
                            // Format the amount separately to avoid nested specifier interpolation
                            let amountString = String(format: "%.2f", expense.amount)
                            Text("Amount: \(group.currency.symbol)\(amountString)")
                            
                            Text("Category: \(expense.category.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Paid by: \(expense.paidBy.name)")
                            
                            // Precompute participants string to avoid nested quotation inside interpolation
                            let participantsString = expense.participants.map { $0.name }.joined(separator: ", ")
                            Text("Participants: \(participantsString)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            if expense.isRecurring {
                                Text("Recurring")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedExpense = expense }
                    .contextMenu {
                        Button(action: { editingExpense = expense }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
                .onDelete { offsets in
                    let expenseVM = ExpenseViewModel(groupVM: groupVM)
                    expenseVM.deleteExpenses(at: offsets, from: group)
                }
            }
            .onAppear { syncGroup() }
            .onReceive(groupVM.$groups) { _ in syncGroup() }
            .navigationTitle(group.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSummary = true }) {
                        Image(systemName: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(group: group, groupVM: groupVM)
            }
            .sheet(item: $editingExpense) { exp in
                AddExpenseView(group: group, groupVM: groupVM, expenseToEdit: exp)
            }
            .sheet(item: $selectedExpense) { exp in
                ExpenseDetailView(groupVM: groupVM, group: group, expense: exp)
            }
            .sheet(isPresented: $showSummary) {
                AnalyticsView(group: group)
            }
            
            // Balances and settlements
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Balances")
                    .font(.headline)
                let expenseVM = ExpenseViewModel(groupVM: groupVM)
                let balances = expenseVM.getBalances(for: group)
                
                ForEach(group.members, id: \.id) { user in
                    let bal = balances[user] ?? 0
                    let absBal = abs(bal)
                    let formatted = String(format: "%.2f", absBal)
                    let sign = bal < 0 ? "-" : ""
                    Text("\(user.name): \(sign)\(group.currency.symbol)\(formatted)")
                        .foregroundColor(bal < 0 ? .red : .green)
                }
                
                if !group.expenses.isEmpty {
                    // Budget progress
                    if let budget = group.budget {
                        let spent = group.expenses.reduce(0) { $0 + $1.amount }
                        let remaining = budget - spent
                        let percent = min(spent / budget, 1.0)
                        let spentString = String(format: "%.2f", spent)
                        let budgetString = String(format: "%.2f", budget)
                        Text("Budget: \(group.currency.symbol)\(spentString) of \(group.currency.symbol)\(budgetString)")
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .frame(height: 8)
                                .foregroundColor(.gray.opacity(0.3))
                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: CGFloat(percent) * 200, height: 8)
                                .foregroundColor(percent <= 1 ? .green : .red)
                        }
                        if remaining < 0 {
                            let overString = String(format: "%.2f", -remaining)
                            Text("Over budget by \(group.currency.symbol)\(overString)")
                                .foregroundColor(.red)
                        } else {
                            let remainingString = String(format: "%.2f", remaining)
                            Text("Remaining budget: \(group.currency.symbol)\(remainingString)")
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Settlements
                    Text("Settlements")
                        .font(.headline)
                        .padding(.top, 4)
                    let settlements = expenseVM.getSettlement(for: group)
                    if settlements.isEmpty {
                        Text("Everyone is settled up!")
                    } else {
                        ForEach(0..<settlements.count, id: \.self) { idx in
                            let s = settlements[idx]
                            HStack {
                                let amountString = String(format: "%.2f", s.amount)
                                Text("\(s.payer.name) pays \(s.payee.name) \(group.currency.symbol)\(amountString)")
                                Spacer()
                                Button(action: {
                                    let evm = ExpenseViewModel(groupVM: groupVM)
                                    evm.recordAdjustment(from: s.payer, to: s.payee, amount: s.amount, in: group)
                                    syncGroup()
                                }) {
                                    Text("Settle")
                                        .font(.caption)
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Activity feed (last five entries)
                if !group.activity.isEmpty {
                    Text("Activity")
                        .font(.headline)
                        .padding(.top, 4)
                    ForEach(group.activity.sorted(by: { $0.date > $1.date }).prefix(5)) { activity in
                        Text(activity.text)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .onAppear { syncGroup() }
    }
    
    private func syncGroup() {
        if let updated = groupVM.groups.first(where: { $0.id == group.id }) {
            group = updated
        }
    }
}
