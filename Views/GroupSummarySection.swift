import SwiftUI

/// Merged summary section: Balances and Activity only. No settlements or settle buttons.
struct GroupSummarySection: View {
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Balances
            if !group.members.isEmpty {
                Text("Balances").font(.headline)
                let expenseVM = ExpenseViewModel(groupVM: groupVM)
                let balances = expenseVM.getBalances(for: group)
                ForEach(group.members, id: \.id) { user in
                    let bal = balances[user] ?? 0
                    // Convert the balance into the user's currency
                    let converted = currencyManager.convert(amount: bal, from: group.currency)
                    let absBal = abs(converted)
                    let sign = converted < 0 ? "-" : ""
                    let formatted = currencyManager.format(amount: absBal)
                    Text("\(user.name): \(sign)\(formatted)")
                        .foregroundColor(converted < 0 ? .red : .green)
                        .font(.system(size: 17, weight: .semibold))
                }
            }

            // Activity feed (last five entries)
            if !group.activity.isEmpty {
                Text("Activity").font(.headline)
                ForEach(group.activity.sorted(by: { $0.date > $1.date }).prefix(5)) { activity in
                    Text(activity.text)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
    }
}
