import SwiftUI
import Charts
import Combine

struct AnalyticsView: View {
    var group: Group
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel
    @Environment(\.presentationMode) private var presentationMode

    @State private var allExpensesForAnalytics: [Expense] = []
    @State private var globalExpenses: [Expense] = []
    @State private var refreshCancellable: AnyCancellable?

    // MARK: - Derived metrics
    private var totalSpent: Double {
        allExpensesForAnalytics.reduce(0) { $0 + $1.amount }
    }

    private var averagePerMember: Double {
        guard !group.members.isEmpty else { return 0 }
        return totalSpent / Double(group.members.count)
    }

    private var categoryTotals: [(ExpenseCategory, Double)] {
        var dict: [ExpenseCategory: Double] = [:]
        for exp in allExpensesForAnalytics {
            dict[exp.category, default: 0] += exp.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var memberTotals: [(User, Double)] {
        var dict: [User: Double] = [:]
        for exp in allExpensesForAnalytics {
            dict[exp.paidBy, default: 0] += exp.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    // Global overview
    private var globalTotalSpent: Double {
        globalExpenses.reduce(0) { $0 + $1.amount }
    }

    private var globalExpenseCount: Int {
        globalExpenses.count
    }

    // MARK: - View
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    GroupBox(label: Text("Global Overview").font(.headline)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total spent: \(group.currency.symbol)\(String(format: "%.2f", globalTotalSpent))")
                            Text("Total entries: \(globalExpenseCount)")
                        }
                        .padding(.vertical, 4)
                    }

                    GroupBox(label: Text("Group Summary (\(group.name))").font(.headline)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total spent: \(group.currency.symbol)\(String(format: "%.2f", totalSpent))")
                            Text("Expenses: \(allExpensesForAnalytics.count)")
                            Text("Avg/member: \(group.currency.symbol)\(String(format: "%.2f", averagePerMember))")
                        }
                        .padding(.vertical, 4)
                    }

                    if !categoryTotals.isEmpty {
                        GroupBox(label: Text("By Category").font(.headline)) {
                            Chart(categoryTotals, id: \.0) { item in
                                BarMark(
                                    x: .value("Category", item.0.displayName),
                                    y: .value("Amount", item.1)
                                )
                                .foregroundStyle(Color.blue)
                            }
                            .frame(height: 200)
                        }
                    }

                    if !memberTotals.isEmpty {
                        GroupBox(label: Text("By Payer").font(.headline)) {
                            Chart(memberTotals, id: \.0) { item in
                                BarMark(
                                    x: .value("Member", item.0.name),
                                    y: .value("Amount", item.1)
                                )
                                .foregroundStyle(Color.green)
                            }
                            .frame(height: 200)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .onAppear {
            print("🟢 [AnalyticsView] onAppear — initializing Combine listeners")
            recomputeAnalytics()
            setupReactiveRefresh()
        }
    }

    // MARK: - Logic
    private func recomputeAnalytics() {
        print("🟣 [AnalyticsView] recomputeAnalytics() triggered")

        // Direct expenses that include members of this group
        let directExpenses = friendsVM.directExpenses.filter { exp in
            exp.participants.contains(where: { group.members.contains($0) })
        }
        allExpensesForAnalytics = group.expenses + directExpenses

        let allGroupExpenses = groupVM.groups.flatMap { $0.expenses }
        globalExpenses = allGroupExpenses + friendsVM.directExpenses

        print("""
              🔍 [AnalyticsView] Group '\(group.name)' recomputed
              - group.expenses: \(group.expenses.count)
              - directExpenses (matching group): \(directExpenses.count)
              - allExpensesForAnalytics: \(allExpensesForAnalytics.count)
              - globalExpenses total: \(globalExpenses.count)
              """)
    }

    private func setupReactiveRefresh() {
        refreshCancellable?.cancel()

        refreshCancellable = Publishers.Merge3(
            groupVM.$groups.map { _ in "groupVM" },
            friendsVM.$directExpenses.map { _ in "directExpenses" },
            friendsVM.$didUpdateExpenses.map { _ in "didUpdateExpenses" }
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { source in
            print("🟠 [AnalyticsView] Combine trigger from \(source)")
            recomputeAnalytics()
        }

        print("🟢 [AnalyticsView] Combine subscriptions attached")
    }
}
