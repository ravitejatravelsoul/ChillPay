import Foundation

class ExpenseViewModel: ObservableObject {
    @Published var groups: [Group]
    let groupVM: GroupViewModel
    
    init(groupVM: GroupViewModel) {
        self.groupVM = groupVM
        self.groups = groupVM.groups
    }
    
    func addExpense(_ expense: Expense, to group: Group) {
        if let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) {
            groupVM.groups[index].expenses.append(expense)
        }
    }
    
    func getBalances(for group: Group) -> [User: Double] {
        var balances: [User: Double] = [:]
        for user in group.members {
            balances[user] = 0.0
        }
        for expense in group.expenses {
            let share = expense.amount / Double(expense.participants.count)
            for participant in expense.participants {
                balances[participant, default: 0.0] -= share
            }
            balances[expense.paidBy, default: 0.0] += expense.amount
        }
        return balances
    }
}
