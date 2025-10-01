import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsVM: FriendsViewModel = FriendsViewModel.shared
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var selectedFriend: User?
    @State private var sortByOwesYou = false

    var filteredFriends: [User] {
        let list = friendsVM.friends
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Friends")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    // Search
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

                    // Actions
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
                                Text("Sort: Name")
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

                // Friends List Card
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
                        FriendRow(friend: friend, friendsVM: friendsVM)
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
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend, friendsVM: friendsVM)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Friend Row

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
                    .foregroundColor(.white) // <-- FIXED: Use white for name
            }
            Spacer()
            // Net balance, colored two-line
            let balance = friendsVM.balanceWith(friend: friend)
            if balance < 0 {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("You owe \(friend.name)")
                    Text("₹\(String(format: "%.2f", abs(balance)))")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.trailing)
            } else if balance > 0 {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(friend.name) owes you")
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

// MARK: - User Avatar Color/Initial Helper

extension User {
    var avatarColor: Color {
        // Assigns a consistent color based on name hash
        let colors: [Color] = [.blue, .green, .red, .pink, .orange, .purple, .teal]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    var initial: String {
        String(name.prefix(1)).uppercased()
    }
}
