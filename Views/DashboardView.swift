import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

    var currentUser: User? {
        friendsVM.friends.first
    }

    var allExpenses: [Expense] {
        groupVM.groups.flatMap { $0.expenses }
    }

    var allActivities: [Activity] {
        groupVM.groups.flatMap { $0.activity }
            .sorted(by: { $0.date > $1.date })
    }

    var allBalances: [User: Double] {
        var balances: [User: Double] = [:]
        for group in groupVM.groups {
            let expenseVM = ExpenseViewModel(groupVM: groupVM)
            let groupBalances = expenseVM.getBalances(for: group)
            for (user, balance) in groupBalances {
                balances[user, default: 0.0] += balance
            }
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
    // Optionally use a generalized formatter for all currencies
    func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol)\(String(format: "%.2f", amount))"
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dashboard")
                        .font(ChillTheme.headerFont)
                        .foregroundColor(ChillTheme.darkText)

                    // Balance gradient card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Balance")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.headline)
                        Text(formattedAmount(totalBalance))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChillTheme.dashboardGradient)
                    .cornerRadius(ChillTheme.cardRadius)

                    // Owe Chips
                    HStack(spacing: 20) {
                        DashboardChip(label: "You Owe", value: formattedAmount(youOwe), color: ChillTheme.chipOwe)
                        DashboardChip(label: "You Are Owed", value: formattedAmount(youAreOwed), color: ChillTheme.chipOwed)
                    }
                }
                .padding(.horizontal)

                // Recent Activity - Only this part scrolls!
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        Spacer()
                        Button(action: {
                            selectedTab = .activity // Switch to Activities tab!
                        }) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(allActivities.prefix(30)) { activity in
                                ActivityRowV2(activity: activity)
                            }
                        }
                    }
                    .frame(height: 340) // Adjust for your UI, e.g. 5-8 rows visible
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
