import Foundation

class ExpenseViewModel: ObservableObject {
    /// Reference to the parent `GroupViewModel` used to update groups when
    /// expenses change.
    let groupVM: GroupViewModel

    init(groupVM: GroupViewModel) {
        self.groupVM = groupVM
    }

    /// Add a new expense to the specified group.
    func addExpense(_ expense: Expense, to group: Group) {
        guard let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        groupVM.groups[index].expenses.append(expense)
        // Use the group's currency symbol when logging amounts
        let symbol = group.currency.symbol
        let amt = String(format: "%.2f", expense.amount)
        groupVM.logActivity(for: group.id, text: "Added expense \(expense.title) for \(symbol)\(amt)")
    }

    /// Update an existing expense within a group.  The expense is matched on its `id`.
    func updateExpense(_ expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        if let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            groupVM.groups[groupIndex].expenses[expenseIndex] = expense
            let symbol = group.currency.symbol
            let amt = String(format: "%.2f", expense.amount)
            groupVM.logActivity(for: group.id, text: "Updated expense \(expense.title) to \(symbol)\(amt)")
        }
    }

    /// Delete expenses at the provided indices from a group.
    func deleteExpenses(at offsets: IndexSet, from group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        // Capture titles before deletion for activity messages
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
        // Apply manual adjustments such as payments or forgiveness
        for adjustment in group.adjustments {
            // If the adjustment references users that are no longer in the group,
            // skip it.  This can happen if a user was removed after the
            // adjustment was recorded.
            guard balances.keys.contains(adjustment.from), balances.keys.contains(adjustment.to) else { continue }
            balances[adjustment.from, default: 0.0] += adjustment.amount
            balances[adjustment.to, default: 0.0] -= adjustment.amount
        }
        return balances
    }

    /// Generate a list of payments required to settle all balances in a group.
    ///
    /// The algorithm pairs users who owe money with those who are owed money
    /// until everyone’s balance reaches zero.  The resulting list contains
    /// tuples where `payer` must pay `payee` the specified `amount`.
    func getSettlement(for group: Group) -> [(payer: User, payee: User, amount: Double)] {
        let balances = getBalances(for: group)
        // Split into creditors (positive balances) and debtors (negative balances)
        var debtors: [(user: User, amount: Double)] = []
        var creditors: [(user: User, amount: Double)] = []
        for (user, balance) in balances {
            if balance < -0.01 {
                debtors.append((user, -balance))
            } else if balance > 0.01 {
                creditors.append((user, balance))
            }
        }
        // Sort both lists so largest balances are matched first
        debtors.sort { $0.amount > $1.amount }
        creditors.sort { $0.amount > $1.amount }
        var settlements: [(payer: User, payee: User, amount: Double)] = []
        var debtorIndex = 0
        var creditorIndex = 0
        while debtorIndex < debtors.count && creditorIndex < creditors.count {
            let debtor = debtors[debtorIndex]
            let creditor = creditors[creditorIndex]
            let amount = min(debtor.amount, creditor.amount)
            settlements.append((payer: debtor.user, payee: creditor.user, amount: amount))
            let newDebtorAmount = debtor.amount - amount
            let newCreditorAmount = creditor.amount - amount
            if newDebtorAmount <= 0.01 {
                debtorIndex += 1
            } else {
                debtors[debtorIndex].amount = newDebtorAmount
            }
            if newCreditorAmount <= 0.01 {
                creditorIndex += 1
            } else {
                creditors[creditorIndex].amount = newCreditorAmount
            }
        }
        return settlements
    }

    /// Record a manual adjustment between two members.  Positive amounts
    /// represent a payment from `from` (the payer) to `to` (the payee),
    /// reducing the payer's debt and the payee's credit.  Negative amounts
    /// can be used to represent debt forgiveness where the payee
    /// relinquishes some or all of what they are owed.
    ///
    /// - Parameters:
    ///   - from: The user who is transferring value (payer or forgiving member).
    ///   - to: The user who is receiving value (payee or forgiven member).
    ///   - amount: The monetary value of the adjustment.  Positive values
    ///     indicate a payment; negative values indicate forgiveness.
    ///   - group: The group in which the adjustment is recorded.
    func recordAdjustment(from: User, to: User, amount: Double, in group: Group) {
        guard let index = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        let adjustment = Adjustment(id: UUID(), from: from, to: to, amount: amount, date: Date())
        groupVM.groups[index].adjustments.append(adjustment)
        // Create a user‑friendly description for the activity log
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

    /// Add a new comment to a specific expense.  The comment is appended
    /// to the existing list of comments on the expense.  After adding
    /// the comment, the expense is updated in the group and an activity
    /// entry is recorded.
    /// - Parameters:
    ///   - text: The textual content of the comment.
    ///   - author: The user who wrote the comment.
    ///   - expense: The expense to which the comment should be added.
    ///   - group: The group containing the expense.
    func addComment(_ text: String, by author: User, to expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        guard let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        var updatedExpense = groupVM.groups[groupIndex].expenses[expenseIndex]
        let comment = Comment(id: UUID(), user: author, text: text, date: Date())
        updatedExpense.comments.append(comment)
        groupVM.groups[groupIndex].expenses[expenseIndex] = updatedExpense
        groupVM.logActivity(for: group.id, text: "\(author.name) commented on \(expense.title)")
    }

    /// Mark a particular expense as settled in the group.
    func settleExpense(_ expense: Expense, in group: Group) {
        guard let groupIndex = groupVM.groups.firstIndex(where: { $0.id == group.id }) else { return }
        guard let expenseIndex = groupVM.groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        groupVM.groups[groupIndex].expenses[expenseIndex].isSettled = true
        groupVM.logActivity(for: group.id, text: "Settled expense '\(expense.title)'")
    }
}
