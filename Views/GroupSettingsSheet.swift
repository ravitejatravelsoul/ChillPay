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
            ZStack {
                ChillTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Text("Group Settings")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 20)

                    ScrollView {
                        VStack(spacing: 24) {

                            // Members Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Members")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                ForEach(group.members) { member in
                                    HStack {
                                        Circle()
                                            .fill(Color.avatarColor(for: member))
                                            .frame(width: 28, height: 28)
                                            .overlay(Text(member.initials).font(.caption).foregroundColor(.white))
                                        Text(member.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(ChillTheme.card)
                            .cornerRadius(18)

                            // Balances Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Balances")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                let balances = ExpenseViewModel(groupVM: groupVM).getBalances(for: group)
                                ForEach(group.members, id: \.id) { user in
                                    let bal = balances[user] ?? 0
                                    HStack {
                                        Text(user.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(bal < 0 ? "-" : "")\(group.currency.symbol)\(abs(bal), specifier: "%.2f")")
                                            .foregroundColor(bal < 0 ? .red : .green)
                                    }
                                }
                            }
                            .padding()
                            .background(ChillTheme.card)
                            .cornerRadius(18)

                            // Settlements Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settlements")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                let settlements = ExpenseViewModel(groupVM: groupVM).getSettlement(for: group)
                                if settlements.isEmpty {
                                    Text("Everyone is settled up!")
                                        .foregroundColor(.green)
                                } else {
                                    ForEach(0..<settlements.count, id: \.self) { idx in
                                        let s = settlements[idx]
                                        Text("\(s.payer.name) pays \(s.payee.name) \(group.currency.symbol)\(String(format: "%.2f", s.amount))")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(ChillTheme.card)
                            .cornerRadius(18)

                            // Simplify Debts Toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $simplifyDebts) {
                                    Text("Simplify Group Debts")
                                        .foregroundColor(.white)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                            }
                            .padding()
                            .background(ChillTheme.card)
                            .cornerRadius(18)

                            // Actions
                            VStack(spacing: 12) {
                                Button(role: .destructive, action: onDeleteGroup) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Group")
                                    }
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(ChillTheme.card)
                                    .cornerRadius(12)
                                }
                                Button(role: .destructive, action: onLeaveGroup) {
                                    HStack {
                                        Image(systemName: "figure.walk")
                                        Text("Leave Group")
                                    }
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(ChillTheme.card)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .onChange(of: simplifyDebts) { newValue, _ in
                onUpdateSimplify(newValue)
            }
        }
    }
}
