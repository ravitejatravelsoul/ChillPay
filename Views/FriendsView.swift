import SwiftUI

enum ActiveSheet: Identifiable {
    case detail(User)
    case addExpense(User)
    
    var id: String {
        switch self {
        case .detail(let user): return "detail-\(user.id)"
        case .addExpense(let user): return "addExpense-\(user.id)"
        }
    }
    var user: User {
        switch self {
        case .detail(let user): return user
        case .addExpense(let user): return user
        }
    }
}

struct FriendsView: View {
    @ObservedObject var friendsVM: FriendsViewModel = FriendsViewModel.shared
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var sortByOwesYou = false
    @State private var lastSheetDismissed = Date()
    @State private var forceRefresh = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var activeSheet: ActiveSheet?

    var filteredFriends: [User] {
        let selfId = friendsVM.currentUser?.id
        let baseList = friendsVM.friends.filter { friend in
            guard let selfId else { return true }
            return friend.id != selfId
        }
        if searchText.isEmpty { return baseList }
        return baseList.filter { friend in
            friend.name.localizedCaseInsensitiveContains(searchText)
                || (friend.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var selfSummary: (totalOwe: Double, totalOwed: Double) {
        guard let selfUser = friendsVM.currentUser else { return (0, 0) }
        let friendsWithoutSelf = friendsVM.friends.filter { $0.id != selfUser.id }
        let totalOwe = friendsWithoutSelf.map { friendsVM.balanceWith(friend: $0) }
            .filter { $0 < -0.01 }
            .reduce(0, +)
        let totalOwed = friendsWithoutSelf.map { friendsVM.balanceWith(friend: $0) }
            .filter { $0 > 0.01 }
            .reduce(0, +)
        return (totalOwe, totalOwed)
    }

    func delayedRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            friendsVM.refreshFriends()
            forceRefresh.toggle()
            if let settlement = friendsVM.lastSettlement {
                celebrationMessage = "All settled with \(settlement.friend.name)! 🎉\n\(settlement.message)"
                showCelebration = true
                friendsVM.lastSettlement = nil
            }
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

                    if let selfUser = friendsVM.currentUser {
                        let summary = selfSummary
                        VStack {
                            HStack {
                                Circle()
                                    .fill(selfUser.avatarColor)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(selfUser.initial)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selfUser.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    if let email = selfUser.email {
                                        Text(email)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.bottom, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                if summary.totalOwe < -0.01 {
                                    Text("You owe others ₹\(String(format: "%.2f", abs(summary.totalOwe)))")
                                        .foregroundColor(.red)
                                        .font(.headline)
                                }
                                if summary.totalOwed > 0.01 {
                                    Text("Others owe you ₹\(String(format: "%.2f", abs(summary.totalOwed)))")
                                        .foregroundColor(.green)
                                        .font(.headline)
                                }
                                if summary.totalOwe >= -0.01 && summary.totalOwed <= 0.01 {
                                    Text("All settled!")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                        .background(ChillTheme.card)
                        .cornerRadius(18)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 2)
                    }

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
                            friendsVM.sortFriendsByOwesYou(sortByOwesYou)
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
                                activeSheet = .detail(friend)
                            }) {
                                FriendRow(friend: friend, friendsVM: friendsVM)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                activeSheet = .addExpense(friend)
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
            .id(forceRefresh)
            .sheet(isPresented: $showAddFriendSheet, onDismiss: {
                lastSheetDismissed = Date()
                delayedRefresh()
            }) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(item: $activeSheet, onDismiss: {
                lastSheetDismissed = Date()
                activeSheet = nil
                delayedRefresh()
            }) { sheet in
                switch sheet {
                case .detail(let friend):
                    FriendDetailView(friend: friend, friendsVM: friendsVM)
                case .addExpense(let friend):
                    AddDirectExpenseView(friend: friend, friendsVM: friendsVM, expenseToEdit: nil)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            friendsVM.refreshFriends()
        }
        .onChange(of: friendsVM.didUpdateExpenses) {
            friendsVM.refreshFriends()
            forceRefresh.toggle()
        }
        .onChange(of: lastSheetDismissed) { _ in }
    }
}

struct FriendRow: View {
    let friend: User
    let friendsVM: FriendsViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
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
