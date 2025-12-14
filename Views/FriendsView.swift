import SwiftUI

// MARK: - Enum for Sheet Management
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

// MARK: - FriendsView
struct FriendsView: View {
    @ObservedObject var friendsVM: FriendsViewModel = FriendsViewModel.shared
    @StateObject var groupVM = GroupViewModel(friendsVM: FriendsViewModel.shared)
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var sortByOwesYou = false
    @State private var lastSheetDismissed = Date()
    @State private var forceRefresh = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var activeSheet: ActiveSheet?

    // MARK: - Filtered Friends
    var filteredFriends: [User] {
        let selfId = friendsVM.currentUser?.id
        let baseList = friendsVM.friends.filter { friend in
            guard let selfId else { return true }
            return friend.id != selfId
        }
        if searchText.isEmpty { return baseList }
        return baseList.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Expense helpers
    func allExpensesWith(friend: User) -> [Expense] {
        let direct = friendsVM.directExpenses.filter {
            $0.participants.contains(where: { $0.id == friend.id })
        }
        let group = groupVM.groups.flatMap { $0.expenses }
            .filter { $0.participants.contains(where: { $0.id == friend.id }) }
        return (direct + group).sorted { $0.date > $1.date }
    }

    func balanceWith(friend: User) -> Double {
        guard let me = friendsVM.currentUser else { return 0 }
        var balance: Double = 0
        // direct
        for e in friendsVM.directExpenses where e.participants.contains(where: { $0.id == friend.id }) {
            let share = e.amount / Double(e.participants.count)
            if e.paidBy.id == me.id { balance += share * Double(e.participants.count - 1) }
            else if e.paidBy.id == friend.id { balance -= share }
        }
        // group
        for e in groupVM.groups.flatMap({ $0.expenses })
        where e.participants.contains(where: { $0.id == friend.id }) {
            let share = e.amount / Double(e.participants.count)
            if e.paidBy.id == me.id { balance += share * Double(e.participants.count - 1) }
            else if e.paidBy.id == friend.id { balance -= share }
        }
        return balance
    }

    var selfSummary: (owe: Double, owed: Double) {
        guard let me = friendsVM.currentUser else { return (0, 0) }
        var owe = 0.0, owed = 0.0
        for f in friendsVM.friends where f.id != me.id {
            let b = balanceWith(friend: f)
            if b < -0.01 { owe += b }
            if b > 0.01 { owed += b }
        }
        return (owe, owed)
    }

    func delayedRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            friendsVM.refreshFriends()
            forceRefresh.toggle()
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                FriendSummaryHeader(
                    friendsVM: friendsVM,
                    searchText: $searchText,
                    showAddFriendSheet: $showAddFriendSheet,
                    sortByOwesYou: $sortByOwesYou
                )

                if let me = friendsVM.currentUser {
                    SelfSummaryCard(user: me, summary: selfSummary)
                }

                if filteredFriends.isEmpty {
                    VStack(alignment: .center) {
                        Text("No friends yet – tap 'Add Friend' to get started.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(ChillTheme.darkText.opacity(0.6))
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(ChillTheme.card)
                    .cornerRadius(28)
                    .padding(.horizontal)
                    .padding(.bottom, 72)
                } else {
                    FriendsListSection(
                        filteredFriends: filteredFriends,
                        friendsVM: friendsVM,
                        groupVM: groupVM,
                        activeSheet: $activeSheet,
                        allExpensesWith: allExpensesWith,
                        balanceWith: balanceWith
                    )
                }
            }
            .id(forceRefresh)
            .sheet(isPresented: $showAddFriendSheet, onDismiss: delayedRefresh) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(item: $activeSheet, onDismiss: delayedRefresh) { sheet in
                switch sheet {
                case .detail(let friend):
                    FriendDetailView(
                        friend: friend,
                        friendsVM: friendsVM,
                        groupVM: groupVM,
                        allExpenses: allExpensesWith(friend: friend),
                        balance: balanceWith(friend: friend)
                    )
                case .addExpense(let friend):
                    AddDirectExpenseView(friend: friend, friendsVM: friendsVM, expenseToEdit: nil)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { friendsVM.refreshFriends() }
    }
}

// MARK: - Header / Summary
struct FriendSummaryHeader: View {
    @ObservedObject var friendsVM: FriendsViewModel
    @Binding var searchText: String
    @Binding var showAddFriendSheet: Bool
    @Binding var sortByOwesYou: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Friends")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(ChillTheme.darkText)
                .padding(.top, 4)

            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search friends...", text: $searchText)
                    .font(.body)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(ChillTheme.card)
            .cornerRadius(16)

            HStack(spacing: 16) {
                Button(action: { showAddFriendSheet = true }) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ChillTheme.accent)
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
                    .background(ChillTheme.card)
                    .foregroundColor(ChillTheme.darkText)
                    .cornerRadius(14)
                }
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(28)
        .padding(.horizontal)
    }
}

struct SelfSummaryCard: View {
    let user: User
    let summary: (owe: Double, owed: Double)

    var body: some View {
        VStack {
            HStack {
                // Use unified AvatarView for the current user
                    AvatarView(user: user)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ChillTheme.darkText)
                        if let email = user.email {
                            Text(email)
                                .font(.system(size: 14))
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                        }
                    }
                Spacer()
            }
            .padding(.bottom, 6)

                if summary.owe < -0.01 {
                    Text("You owe others ₹\(String(format: "%.2f", abs(summary.owe)))")
                        .foregroundColor(.red)
                }
                if summary.owed > 0.01 {
                    Text("Others owe you ₹\(String(format: "%.2f", abs(summary.owed)))")
                        .foregroundColor(.green)
                }
                if summary.owe >= -0.01 && summary.owed <= 0.01 {
                    Text("All settled!")
                        .foregroundColor(ChillTheme.darkText.opacity(0.5))
                }
        }
        .font(.headline)
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
        .padding(.horizontal)
    }
}

// ✅ FIXED VERSION — no @escaping on stored properties
struct FriendsListSection: View {
    let filteredFriends: [User]
    let friendsVM: FriendsViewModel
    let groupVM: GroupViewModel
    @Binding var activeSheet: ActiveSheet?
    let allExpensesWith: (User) -> [Expense]
    let balanceWith: (User) -> Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Your Friends")
                    .font(.headline)
                    .foregroundColor(ChillTheme.darkText)
                Spacer()
                Text("\(filteredFriends.count) total")
                    .font(.subheadline)
                    .foregroundColor(ChillTheme.darkText.opacity(0.6))
            }
            .padding(.bottom, 10)

            ForEach(filteredFriends) { friend in
                HStack {
                    Button { activeSheet = .detail(friend) } label: {
                        FriendRow(
                            friend: friend,
                            friendsVM: friendsVM,
                            groupVM: groupVM,
                            allExpenses: allExpensesWith(friend),
                            balance: balanceWith(friend)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button { activeSheet = .addExpense(friend) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundColor(ChillTheme.accent)
                        .background(ChillTheme.card)
                        .cornerRadius(10)
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
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: User
    let friendsVM: FriendsViewModel
    let groupVM: GroupViewModel
    let allExpenses: [Expense]
    let balance: Double

    var body: some View {
        HStack(spacing: 16) {
            // Use unified AvatarView for each friend
            AvatarView(user: friend)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ChillTheme.darkText)
                if let email = friend.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(ChillTheme.darkText.opacity(0.6))
                }
                Text("Expenses: \(allExpenses.count)")
                    .font(.caption)
                    .foregroundColor(ChillTheme.darkText.opacity(0.6))
            }

            Spacer()

            let epsilon = 0.01
            if balance < -epsilon {
                VStack(alignment: .trailing) {
                    Text("You owe")
                    Text("₹\(String(format: "%.2f", abs(balance)))")
                }
                .foregroundColor(.red)
            } else if balance > epsilon {
                VStack(alignment: .trailing) {
                    Text("Owes you")
                    Text("₹\(String(format: "%.2f", abs(balance)))")
                }
                .foregroundColor(.green)
            } else {
                Text("Settled")
                    .foregroundColor(ChillTheme.darkText.opacity(0.5))
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .padding(.vertical, 10)
    }
}

// The avatar colour and initial helpers are now provided by the User model itself.
