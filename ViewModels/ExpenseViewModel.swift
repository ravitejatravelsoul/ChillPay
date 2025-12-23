import Foundation

final class ExpenseViewModel: ObservableObject {
    let groupVM: GroupViewModel

    init(groupVM: GroupViewModel) {
        self.groupVM = groupVM
    }

    func addExpense(_ expense: Expense, to group: Group) {
        groupVM.addExpense(expense, to: group)
    }

    func updateExpense(_ expense: Expense, in group: Group) {
        groupVM.updateExpense(expense, in: group)
    }

    func deleteExpenses(at offsets: IndexSet, from group: Group) {
        // translate offsets -> actual Expense objects
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        let expenses = groupVM.groups[groupIndex].expenses

        let toDelete = offsets.compactMap { idx -> Expense? in
            guard idx >= 0, idx < expenses.count else { return nil }
            return expenses[idx]
        }

        for exp in toDelete {
            groupVM.deleteExpense(exp, from: group)
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
            guard balances.keys.contains(adjustment.from),
                  balances.keys.contains(adjustment.to) else { continue }
            balances[adjustment.from, default: 0.0] += adjustment.amount
            balances[adjustment.to, default: 0.0] -= adjustment.amount
        }

        return balances
    }

    func getSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        if group.simplifyDebts {
            return getSimplifiedSettlement(for: group)
        } else {
            return getStandardSettlement(for: group)
        }
    }

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
                if creditors[i].amount <= 0.01 || amountOwed <= 0.01 { continue }
                let payment = min(amountOwed, creditors[i].amount)
                settlements.append((payer: debtor.user, payee: creditors[i].user, amount: payment))
                amountOwed -= payment
                creditors[i].amount -= payment
            }
        }

        return settlements
    }

    private func getSimplifiedSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        var balances = getBalances(for: group)
        balances = balances.mapValues { abs($0) < 0.01 ? 0 : $0 }

        var arr = balances.map { ($0.key, $0.value) }
        arr.sort { $0.1 < $1.1 }

        var settlements: [(payer: User, payee: User, amount: Double)] = []
        var i = 0
        var j = arr.count - 1

        while i < j {
            let (debtor, debt) = arr[i]
            let (creditor, credit) = arr[j]

            if debt == 0 { i += 1; continue }
            if credit == 0 { j -= 1; continue }

            let amount = min(-debt, credit)
            if amount <= 0.01 {
                if -debt < credit { i += 1 } else { j -= 1 }
                continue
            }

            settlements.append((payer: debtor, payee: creditor, amount: amount))
            arr[i].1 += amount
            arr[j].1 -= amount

            if abs(arr[i].1) < 0.01 { i += 1 }
            if abs(arr[j].1) < 0.01 { j -= 1 }
        }

        return settlements
    }

    func recordAdjustment(from: User, to: User, amount: Double, in group: Group) {
        guard let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }

        let adjustment = Adjustment(id: UUID(), from: from, to: to, amount: amount, date: Date())
        groupVM.groups[index].adjustments.append(adjustment)

        let formattedAmount = String(format: "%.2f", abs(amount))
        let currencySymbol = group.currency.symbol
        let description: String = amount > 0
            ? "\(from.name) paid \(to.name) \(currencySymbol)\(formattedAmount)"
            : "\(from.name) forgave \(to.name) \(currencySymbol)\(formattedAmount)"

        groupVM.logActivity(for: group.id, text: description)
        groupVM.updateGroup(groupVM.groups[index]) // persists meta changes
    }

    func addComment(_ text: String, by author: User, to expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        guard let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        var updatedExpense = groupVM.groups[groupIndex].expenses[expenseIndex]
        let comment = Comment(id: UUID(), user: author, text: text, date: Date())
        updatedExpense.comments.append(comment)

        groupVM.groups[groupIndex].expenses[expenseIndex] = updatedExpense
        groupVM.logActivity(for: group.id, text: "\(author.name) commented on \(expense.title)")

        // Persist the expense update (subcollection)
        groupVM.updateExpense(updatedExpense, in: group)
    }

    func settleExpense(_ expense: Expense, in group: Group) {
        // If you later add an `isSettled` field, update it here and persist using updateExpense(...)
        groupVM.logActivity(for: group.id, text: "Settled expense '\(expense.title)'")
        groupVM.updateGroup(group) // meta/activity persistence
    }
}
