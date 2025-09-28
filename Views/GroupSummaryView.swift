import SwiftUI

struct GroupSummaryView: View {
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    @Binding var showAnalytics: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Balances
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
            }

            // Settlements
            if !group.expenses.isEmpty {
                Text("Settlements").font(.headline).padding(.top, 4)
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
                Text("Activity").font(.headline).padding(.top, 4)
                ForEach(group.activity.sorted(by: { $0.date > $1.date }).prefix(5)) { activity in
                    Text(activity.text)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            // Analytics button
            Button(action: { showAnalytics = true }) {
                HStack {
                    Image(systemName: "chart.bar")
                    Text("See Full Analytics")
                }
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}
