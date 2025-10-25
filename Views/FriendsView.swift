import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsVM: FriendsViewModel = FriendsViewModel.shared
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var showAddExpenseSheet = false
    @State private var showFriendDetail = false
    @State private var selectedFriend: User?
    @State private var sortByOwesYou = false
    @State private var lastSheetDismissed: Date = Date()
    @State private var forceRefresh = false // NEW: dummy state to force view update

    var filteredFriends: [User] {
        let list = friendsVM.friends
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }

    func delayedRefresh() {
        // Guarantee a refresh 0.2 seconds after sheet dismiss (works around SwiftUI bug)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("[FriendsView] delayedRefresh called")
            friendsVM.refreshFriends()
            forceRefresh.toggle() // NEW: force view refresh
        }
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Friends")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search friends...", text: $searchText)
                            .font(.body)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    HStack(spacing: 16) {
                        Button(action: { showAddFriendSheet = true }) {
                            Label("Add Friend", systemImage: "person.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        Button(action: {
                            sortByOwesYou.toggle()
                            friendsVM.sortByOwesYou(sort: sortByOwesYou)
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down.circle")
                                Text(sortByOwesYou ? "Sort: Owes You" : "Sort: Name")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray4))
                            .foregroundColor(.gray)
                            .cornerRadius(14)
                        }
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(28)
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Your Friends")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(filteredFriends.count) total")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 10)
                    ForEach(filteredFriends) { friend in
                        HStack {
                            Button(action: {
                                selectedFriend = friend
                                showFriendDetail = true
                            }) {
                                FriendRow(friend: friend, friendsVM: friendsVM)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: {
                                selectedFriend = friend
                                showAddExpenseSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                    .padding(.leading, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        if friend.id != filteredFriends.last?.id {
                            Divider().background(Color(.systemGray4))
                        }
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(28)
                .padding(.horizontal)
                .padding(.bottom, 72)
                Spacer()
            }
            .id(forceRefresh) // NEW: force view re-render
            .sheet(isPresented: $showAddFriendSheet, onDismiss: {
                lastSheetDismissed = Date()
                delayedRefresh()
            }) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(isPresented: $showAddExpenseSheet, onDismiss: {
                lastSheetDismissed = Date()
                delayedRefresh()
            }) {
                if let friend = selectedFriend {
                    AddDirectExpenseView(friend: friend, friendsVM: friendsVM, expenseToEdit: nil)
                } else {
                    Text("Loading...").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showFriendDetail, onDismiss: {
                lastSheetDismissed = Date()
                delayedRefresh()
            }) {
                if let friend = selectedFriend {
                    FriendDetailView(friend: friend, friendsVM: friendsVM)
                } else {
                    Text("Loading...").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("[FriendsView] onAppear called")
            friendsVM.refreshFriends()
        }
        .onChange(of: friendsVM.didUpdateExpenses) {
            print("[FriendsView] onChange didUpdateExpenses called")
            friendsVM.refreshFriends()
            forceRefresh.toggle() // NEW: force view re-render
        }
        .onChange(of: lastSheetDismissed) {
            // Just a trigger for the timer-based refresh.
            print("[FriendsView] onChange lastSheetDismissed called")
        }
    }
}

// --- FriendRow shows amount or "Settled" as required ---
struct FriendRow: View {
    let friend: User
    let friendsVM: FriendsViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Avatar (colored circle with initial)
            Circle()
                .fill(friend.avatarColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(friend.initial)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            let balance = friendsVM.balanceWith(friend: friend)
            let epsilon = 0.01
            if balance < -epsilon {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("You owe")
                    Text("₹\(String(format: "%.2f", abs(balance)))")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.trailing)
            } else if balance > epsilon {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Owes you")
                    Text("₹\(String(format: "%.2f", abs(balance)))")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .multilineTextAlignment(.trailing)
            } else {
                Text("Settled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
    }
}

// --- Avatar helpers ---
extension User {
    var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .red, .pink, .orange, .purple, .teal]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    var initial: String {
        String(name.prefix(1)).uppercased()
    }
}
