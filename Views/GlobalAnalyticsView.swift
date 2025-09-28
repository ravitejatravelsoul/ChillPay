import SwiftUI
import Charts

struct GlobalAnalyticsView: View {
    @EnvironmentObject var groupVM: GroupViewModel

    // Combine all expenses from all groups
    private var allExpenses: [Expense] {
        groupVM.groups.flatMap { $0.expenses }
    }
    // Combine all users from all groups (unique by id)
    private var allUsers: [User] {
        Array(Set(groupVM.groups.flatMap { $0.members }))
    }
    // Combine all currencies used (for now, use the symbol from the first group)
    private var currencySymbol: String {
        groupVM.groups.first?.currency.symbol ?? "$"
    }
    // Analytics calculations
    private var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        var dict: [ExpenseCategory: Double] = [:]
        for expense in allExpenses {
            dict[expense.category, default: 0] += expense.amount
        }
        return dict.map { ($0.key, $0.value) }.sorted(by: { $0.total > $1.total })
    }
    private var memberTotals: [(user: User, total: Double)] {
        var dict: [User: Double] = [:]
        for expense in allExpenses {
            dict[expense.paidBy, default: 0] += expense.amount
        }
        return dict.map { ($0.key, $0.value) }.sorted(by: { $0.total > $1.total })
    }
    private var totalSpent: Double {
        allExpenses.reduce(0) { $0 + $1.amount }
    }
    private var averagePerMember: Double {
        guard !allUsers.isEmpty else { return 0 }
        return totalSpent / Double(allUsers.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Analytics")
                .font(.title2)
                .bold()
                .padding(.top, 8)

            GroupBox(label: Text("Summary").font(.headline)) {
                VStack(alignment: .leading, spacing: 4) {
                    let totalSpentString = String(format: "%.2f", totalSpent)
                    let averagePerMemberString = String(format: "%.2f", averagePerMember)
                    Text("Total spent: \(currencySymbol)\(totalSpentString)")
                    Text("Total expenses: \(allExpenses.count)")
                    Text("Unique members: \(allUsers.count)")
                    Text("Average per member: \(currencySymbol)\(averagePerMemberString)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !categoryTotals.isEmpty {
                GroupBox(label: Text("By Category").font(.headline)) {
                    Chart(categoryTotals, id: \.category) { item in
                        BarMark(
                            x: .value("Category", item.category.displayName),
                            y: .value("Amount", item.total)
                        )
                        .foregroundStyle(Color.blue)
                    }
                    .frame(height: 200)
                    .chartYAxisLabel("Amount")
                    .chartXAxisLabel("Category")
                }
            }

            if !memberTotals.isEmpty {
                GroupBox(label: Text("By Payer").font(.headline)) {
                    Chart(memberTotals, id: \.user) { item in
                        BarMark(
                            x: .value("Member", item.user.name),
                            y: .value("Amount", item.total)
                        )
                        .foregroundStyle(Color.green)
                    }
                    .frame(height: 200)
                    .chartYAxisLabel("Amount")
                    .chartXAxisLabel("Member")
                }
            }
        }
        .padding(.bottom)
    }
}
