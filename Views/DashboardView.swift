import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

    @State private var recentActivities: [Activity] = []

    // MARK: - Derived Data
    var currentUser: User? { friendsVM.currentUser }

    var allExpenses: [Expense] {
        groupVM.groups.flatMap { $0.expenses } + friendsVM.directExpenses
    }

    var allBalances: [User: Double] {
        var balances: [User: Double] = [:]

        // Group balances
        for group in groupVM.groups {
            let expenseVM = ExpenseViewModel(groupVM: groupVM)
            let groupBalances = expenseVM.getBalances(for: group)
            for (user, balance) in groupBalances {
                balances[user, default: 0.0] += balance
            }
        }

        // Direct expenses
        for expense in friendsVM.directExpenses {
            let splitAmount = expense.amount / Double(expense.participants.count)
            for user in expense.participants {
                balances[user, default: 0.0] -= splitAmount
            }
            balances[expense.paidBy, default: 0.0] += expense.amount
        }

        return balances
    }

    var totalBalance: Double {
        guard let user = currentUser else { return 0 }
        return allBalances[user] ?? 0
    }

    var youOwe: Double {
        guard let user = currentUser else { return 0 }
        let value = allBalances[user] ?? 0
        return value < 0 ? abs(value) : 0
    }

    var youAreOwed: Double {
        guard let user = currentUser else { return 0 }
        let value = allBalances[user] ?? 0
        return value > 0 ? value : 0
    }

    var currencySymbol: String {
        groupVM.groups.first?.currency.symbol ?? "$"
    }

    func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(String(format: "%.2f", amount))"
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dashboard")
                        .font(ChillTheme.headerFont)
                        .foregroundColor(ChillTheme.darkText)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Balance")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.headline)

                        Text(formattedAmount(totalBalance))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .animation(.easeInOut, value: totalBalance)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChillTheme.dashboardGradient)
                    .cornerRadius(ChillTheme.cardRadius)

                    HStack(spacing: 20) {
                        DashboardChip(label: "You Owe",
                                      value: formattedAmount(youOwe),
                                      color: ChillTheme.chipOwe)
                        DashboardChip(label: "You Are Owed",
                                      value: formattedAmount(youAreOwed),
                                      color: ChillTheme.chipOwed)
                    }
                }
                .padding(.horizontal)

                // MARK: - Recent Activity
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        Spacer()
                        Button(action: { selectedTab = .activity }) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(recentActivities.prefix(30)) { activity in
                                ActivityRowV2(activity: activity)
                            }
                        }
                    }
                    .frame(height: 340)
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(ChillTheme.cardRadius)
                .padding(.horizontal)
                .padding(.bottom, 72)

                Spacer(minLength: 0)
            }
        }
        .navigationBarHidden(true)

        // 🔥 Real-time updates for Dashboard
        .onReceive(groupVM.$groups) { _ in
            updateRecentActivity()
        }
        .onReceive(groupVM.$globalActivity) { _ in
            updateRecentActivity()
        }
        .onReceive(friendsVM.$didUpdateExpenses) { _ in
            updateRecentActivity()
        }
        .onAppear {
            updateRecentActivity()
        }
    }

    // MARK: - Helpers
    private func updateRecentActivity() {
        let merged = groupVM.globalActivity +
                     friendsVM.directExpenses.map {
                         let formattedAmount = String(format: "%.2f", $0.amount)
                         return Activity(
                             id: $0.id,
                             text: "\($0.paidBy.name) paid \(formattedAmount) for \($0.title)",
                             date: $0.date
                         )
                     }

        recentActivities = merged.sorted { $0.date > $1.date }

        print("DEBUG: [DashboardView] recentActivities refreshed — count:", recentActivities.count)
    }
}

// MARK: - Components
struct DashboardChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(ChillTheme.captionFont)
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
        }
        .frame(width: 120, height: 54)
        .background(color)
        .cornerRadius(ChillTheme.chipRadius)
        .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct ActivityRowV2: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(ChillTheme.accent.opacity(0.14))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(ChillTheme.accent)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.text)
                    .foregroundColor(ChillTheme.darkText)
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
