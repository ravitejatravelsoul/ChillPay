import SwiftUI
import Charts

struct CategoryTotal: Identifiable {
    let id = UUID()
    let category: ExpenseCategory
    let total: Double
}

struct MemberTotal: Identifiable {
    let id = UUID()
    let user: User
    let total: Double
}

struct GlobalAnalyticsView: View {
    @EnvironmentObject var groupVM: GroupViewModel

    var body: some View {
        // Prepare data
        let allExpenses: [Expense] = groupVM.groups.flatMap { $0.expenses }
        let allUsers: [User] = Array(Set(groupVM.groups.flatMap { $0.members }))
        let currencySymbol: String = groupVM.groups.first?.currency.symbol ?? "$"

        let categoryTotals: [CategoryTotal] = {
            var dict = [ExpenseCategory: Double]()
            for exp in allExpenses {
                dict[exp.category, default: 0] += exp.amount
            }
            let array = dict.map { CategoryTotal(category: $0.key, total: $0.value) }
            return array.sorted { $0.total > $1.total }
        }()

        let memberTotals: [MemberTotal] = {
            var dict = [User: Double]()
            for exp in allExpenses {
                dict[exp.paidBy, default: 0] += exp.amount
            }
            let array = dict.map { MemberTotal(user: $0.key, total: $0.value) }
            return array.sorted { $0.total > $1.total }
        }()

        let totalSpent = allExpenses.reduce(0) { $0 + $1.amount }
        let averagePerMember = allUsers.isEmpty ? 0 : totalSpent / Double(allUsers.count)
        let totalSpentString = String(format: "%.2f", totalSpent)
        let averagePerMemberString = String(format: "%.2f", averagePerMember)

        return ZStack {
            ChillTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Global Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    // Summary Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Total spent: \(currencySymbol)\(totalSpentString)").foregroundColor(.white)
                        Text("Total expenses: \(allExpenses.count)").foregroundColor(.white)
                        Text("Unique members: \(allUsers.count)").foregroundColor(.white)
                        Text("Average per member: \(currencySymbol)\(averagePerMemberString)").foregroundColor(.white)
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(20)

                    // Category Chart
                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Category")
                                .font(.headline)
                                .foregroundColor(.white)
                            Chart(categoryTotals) { item in
                                BarMark(
                                    x: .value("Category", item.category.displayName),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(Color.blue)
                            }
                            .chartXAxis {
                                AxisMarks(position: .bottom) { value in
                                    AxisValueLabel() {
                                        if let cat = value.as(String.self) {
                                            Text(cat).foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel() {
                                        if let num = value.as(Double.self) {
                                            Text(String(format: "%.0f", num)).foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .background(Color.clear)
                        }
                        .padding()
                        .background(ChillTheme.card)
                        .cornerRadius(20)
                    }

                    // Member Chart
                    if !memberTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Payer")
                                .font(.headline)
                                .foregroundColor(.white)
                            Chart(memberTotals) { item in
                                BarMark(
                                    x: .value("Member", item.user.name),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(Color.green)
                            }
                            .chartXAxis {
                                AxisMarks(position: .bottom) { value in
                                    AxisValueLabel() {
                                        if let name = value.as(String.self) {
                                            Text(name).foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel() {
                                        if let num = value.as(Double.self) {
                                            Text(String(format: "%.0f", num)).foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .background(Color.clear)
                        }
                        .padding()
                        .background(ChillTheme.card)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}
