import SwiftUI

struct FriendDetailView: View {
    let friend: User
    @ObservedObject var friendsVM: FriendsViewModel
    @State private var showAddExpense = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    AvatarView(user: friend)
                        .frame(width: 60, height: 60)
                    VStack(alignment: .leading) {
                        Text(friend.name).font(.title2).bold()
                        if let email = friend.email {
                            Text(email).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                // Balance
                let balance = friendsVM.balanceWith(friend: friend)
                HStack {
                    Text("Balance with \(friend.name):")
                    Text(friendsVM.balanceString(balance, friend: friend))
                        .foregroundColor(friendsVM.balanceColor(balance))
                        .font(.headline)
                }

                // Actions
                HStack {
                    Button(action: { showAddExpense = true }) {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    if balance != 0 {
                        Button(action: { friendsVM.settleUpWith(friend: friend) }) {
                            Label("Settle Up", systemImage: "arrow.right.arrow.left.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.bottom)

                // Transaction history
                Text("History")
                    .font(.title3).bold()
                List(friendsVM.historyWith(friend: friend)) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.text)
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle(friend.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddDirectExpenseView(friend: friend, friendsVM: friendsVM)
            }
        }
    }
}
