import SwiftUI

/// Merged summary section: Balances and Activity only. No settlements or settle buttons.
struct GroupSummarySection: View {
    @ObservedObject var groupVM: GroupViewModel
    var group: Group

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Balances
            if !group.members.isEmpty {
                Text("Balances").font(.headline)
                let expenseVM = ExpenseViewModel(groupVM: groupVM)
                let balances = expenseVM.getBalances(for: group)
                ForEach(group.members, id: \.id) { user in
                    let bal = balances[user] ?? 0
                    let absBal = abs(bal)
                    let formatted = String(format: "%.2f", absBal)
                    let sign = bal < 0 ? "-" : ""
                    Text("\(user.name): \(sign)\(group.currency.symbol)\(formatted)")
                        .foregroundColor(bal < 0 ? .red : .green)
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
