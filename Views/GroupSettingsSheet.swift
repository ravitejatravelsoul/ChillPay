import SwiftUI

struct GroupSettingsSheet: View {
    let groupVM: GroupViewModel
    let friendsVM: FriendsViewModel
    let group: Group
    @State var simplifyDebts: Bool
    let onUpdateSimplify: (Bool) -> Void
    let onDeleteGroup: () -> Void
    let onLeaveGroup: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Members")) {
                    ForEach(group.members) { member in
                        HStack {
                            Circle()
                                .fill(Color.avatarColor(for: member))
                                .frame(width: 28, height: 28)
                                .overlay(Text(member.initials).font(.caption).foregroundColor(.white))
                            Text(member.name)
                            Spacer()
                        }
                    }
                }
                Section(header: Text("Balances")) {
                    let balances = ExpenseViewModel(groupVM: groupVM).getBalances(for: group)
                    ForEach(group.members, id: \.id) { user in
                        let bal = balances[user] ?? 0
                        HStack {
                            Text(user.name)
                            Spacer()
                            Text("\(bal < 0 ? "-" : "")\(group.currency.symbol)\(abs(bal), specifier: "%.2f")")
                                .foregroundColor(bal < 0 ? .red : .green)
                        }
                    }
                }
                Section(header: Text("Settlements")) {
                    let settlements = ExpenseViewModel(groupVM: groupVM).getSettlement(for: group)
                    if settlements.isEmpty {
                        Text("Everyone is settled up!")
                            .foregroundColor(.green)
                    } else {
                        ForEach(0..<settlements.count, id: \.self) { idx in
                            let s = settlements[idx]
                            Text("\(s.payer.name) pays \(s.payee.name) \(group.currency.symbol)\(String(format: "%.2f", s.amount))")
                        }
                    }
                }
                Section {
                    Toggle("Simplify Group Debts", isOn: $simplifyDebts)
                }
                Section {
                    Button(role: .destructive, action: onDeleteGroup) {
                        Label("Delete Group", systemImage: "trash")
                    }
                    Button(role: .destructive, action: onLeaveGroup) {
                        Label("Leave Group", systemImage: "figure.walk")
                    }
                }
            }
            .navigationTitle("Group Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: simplifyDebts) { newValue, _ in
            onUpdateSimplify(newValue)
        }
    }
}
