import Foundation

class ExpenseViewModel: ObservableObject {
    let groupVM: GroupViewModel

    init(groupVM: GroupViewModel) {
        self.groupVM = groupVM
    }

    func addExpense(_ expense: Expense, to group: Group) {
        guard let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        groupVM.groups[index].expenses.append(expense)
        let symbol = group.currency.symbol
        let amt = String(format: "%.2f", expense.amount)
        groupVM.logActivity(for: group.id, text: "Added expense \(expense.title) for \(symbol)\(amt)")
    }

    func updateExpense(_ expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        if let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            groupVM.groups[groupIndex].expenses[expenseIndex] = expense
            let symbol = group.currency.symbol
            let amt = String(format: "%.2f", expense.amount)
            groupVM.logActivity(for: group.id, text: "Updated expense \(expense.title) to \(symbol)\(amt)")
        }
    }

    func deleteExpenses(at offsets: IndexSet, from group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        let titles = offsets.compactMap { offset -> String? in
            guard offset < groupVM.groups[groupIndex].expenses.count else { return nil }
            return groupVM.groups[groupIndex].expenses[offset].title
        }
        groupVM.groups[groupIndex].expenses.remove(atOffsets: offsets)
        for title in titles {
            groupVM.logActivity(for: group.id, text: "Deleted expense \(title)")
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
        for adjustment in group.adjustments {
            guard balances.keys.contains(adjustment.from), balances.keys.contains(adjustment.to) else { continue }
            balances[adjustment.from, default: 0.0] += adjustment.amount
            balances[adjustment.to, default: 0.0] -= adjustment.amount
        }
        return balances
    }

    /// Returns settlements using either simplified or standard logic based on group.simplifyDebts.
    func getSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        if group.simplifyDebts {
            return getSimplifiedSettlement(for: group)
        } else {
            return getStandardSettlement(for: group)
        }
    }

    // Standard settlements: Each debtor pays each creditor in order, NO optimization/minimization.
    private func getStandardSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        let balances = getBalances(for: group)
        var debtors: [(user: User, amount: Double)] = []
        var creditors: [(user: User, amount: Double)] = []
        for (user, balance) in balances {
            if balance < -0.01 {
                debtors.append((user, -balance))
            } else if balance > 0.01 {
                creditors.append((user, balance))
            }
        }
        var settlements: [(payer: User, payee: User, amount: Double)] = []
        for debtor in debtors {
            var amountOwed = debtor.amount
            for i in creditors.indices {
                let creditor = creditors[i]
                if creditor.amount <= 0.01 || amountOwed <= 0.01 { continue }
                let payment = min(amountOwed, creditor.amount)
                settlements.append((payer: debtor.user, payee: creditor.user, amount: payment))
                amountOwed -= payment
                // Mutate local creditors array, not a variable
                creditors[i].amount -= payment
            }
        }
        return settlements
    }

    // Simplified settlements: Minimize number of transactions.
    private func getSimplifiedSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        var balances = getBalances(for: group)
        balances = balances.mapValues { abs($0) < 0.01 ? 0 : $0 }
        var balancesArray = balances.map { ($0.key, $0.value) }
        balancesArray.sort { $0.1 < $1.1 }
        var settlements: [(payer: User, payee: User, amount: Double)] = []
        var i = 0
        var j = balancesArray.count - 1
        while i < j {
            let (debtor, debt) = balancesArray[i]
            let (creditor, credit) = balancesArray[j]
            if debt == 0 {
                i += 1
                continue
            }
            if credit == 0 {
                j -= 1
                continue
            }
            let amount = min(-debt, credit)
            if amount <= 0.01 {
                if -debt < credit {
                    i += 1
                } else {
                    j -= 1
                }
                continue
            }
            settlements.append((payer: debtor, payee: creditor, amount: amount))
            balancesArray[i].1 += amount
            balancesArray[j].1 -= amount
            if abs(balancesArray[i].1) < 0.01 { i += 1 }
            if abs(balancesArray[j].1) < 0.01 { j -= 1 }
        }
        return settlements
    }

    func recordAdjustment(from: User, to: User, amount: Double, in group: Group) {
        guard let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        let adjustment = Adjustment(id: UUID(), from: from, to: to, amount: amount, date: Date())
        groupVM.groups[index].adjustments.append(adjustment)
        let formattedAmount = String(format: "%.2f", abs(amount))
        let currencySymbol = group.currency.symbol
        let description: String
        if amount > 0 {
            description = "\(from.name) paid \(to.name) \(currencySymbol)\(formattedAmount)"
        } else {
            description = "\(from.name) forgave \(to.name) \(currencySymbol)\(formattedAmount)"
        }
        groupVM.logActivity(for: group.id, text: description)
    }

    func addComment(_ text: String, by author: User, to expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        if let _ = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            var updatedExpense = expense
            let comment = Comment(id: UUID(), user: author, text: text, date: Date())
            updatedExpense.comments.append(comment)
            // update expense in group
            if let idx = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == updatedExpense.id }) {
                groupVM.groups[groupIndex].expenses[idx] = updatedExpense
            }
            groupVM.logActivity(for: group.id, text: "\(author.name) commented on \(expense.title)")
        }
    }

    func settleExpense(_ expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        if groupVM.groups[groupIndex].expenses.contains(where: { $0.id == expense.id }) {
            // Uncomment next if your Expense struct includes isSettled:
            // groupVM.groups[groupIndex].expenses[expenseIndex].isSettled = true
            groupVM.logActivity(for: group.id, text: "Settled expense '\(expense.title)'")
        }
    }
}
