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
    @State private var debugCounter = 0

    // MARK: - Computed Metrics
    private var totalSpent: Double {
        allExpensesForAnalytics.reduce(0) { $0 + max(0, $1.amount) }
    }

    private var averagePerMember: Double {
        guard !group.members.isEmpty else { return 0 }
        let avg = totalSpent / Double(group.members.count)
        return avg.isFinite ? avg : 0
    }

    private var categoryTotals: [(ExpenseCategory, Double)] {
        var dict: [ExpenseCategory: Double] = [:]
        for exp in allExpensesForAnalytics where exp.amount.isFinite && exp.amount > 0 {
            dict[exp.category, default: 0] += exp.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var memberTotals: [(User, Double)] {
        var dict: [User: Double] = [:]
        for exp in allExpensesForAnalytics where exp.amount.isFinite && exp.amount > 0 {
            dict[exp.paidBy, default: 0] += exp.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var globalTotalSpent: Double {
        globalExpenses.reduce(0) { $0 + max(0, $1.amount) }
    }

    private var globalExpenseCount: Int {
        globalExpenses.count
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // --- Global Overview ---
                    GroupBox(label: Text("Global Overview").font(.headline).foregroundColor(ChillTheme.darkText)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total spent: \(group.currency.symbol)\(String(format: "%.2f", globalTotalSpent))")
                                .foregroundColor(ChillTheme.darkText)
                            Text("Total entries: \(globalExpenseCount)")
                                .foregroundColor(ChillTheme.darkText)
                        }
                        .padding(.vertical, 4)
                    }

                    // --- Group Summary ---
                    GroupBox(label: Text("Group Summary (\(group.name))").font(.headline).foregroundColor(ChillTheme.darkText)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total spent: \(group.currency.symbol)\(String(format: "%.2f", totalSpent))")
                                .foregroundColor(ChillTheme.darkText)
                            Text("Expenses: \(allExpensesForAnalytics.count)")
                                .foregroundColor(ChillTheme.darkText)
                            Text("Avg/member: \(group.currency.symbol)\(String(format: "%.2f", averagePerMember))")
                                .foregroundColor(ChillTheme.darkText)
                        }
                        .padding(.vertical, 4)
                    }

                    // --- Category Chart ---
                    if !categoryTotals.isEmpty {
                        GroupBox(label: Text("By Category").font(.headline).foregroundColor(ChillTheme.darkText)) {
                            Chart(categoryTotals, id: \.0) { item in
                                BarMark(
                                    x: .value("Category", item.0.displayName),
                                    y: .value("Amount", item.1)
                                )
                                .foregroundStyle(ChillTheme.accent)
                            }
                            .id(debugCounter) // force refresh
                            .frame(height: 200)
                        }
                    } else {
                        // Empty state when no category data
                        GroupBox(label: Text("By Category").font(.headline).foregroundColor(ChillTheme.darkText)) {
                            Text("Not enough data yet – start adding expenses to see category insights.")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                    }

                    // --- Payer Chart ---
                    if !memberTotals.isEmpty {
                        GroupBox(label: Text("By Payer").font(.headline).foregroundColor(ChillTheme.darkText)) {
                            Chart(memberTotals, id: \.0) { item in
                                BarMark(
                                    x: .value("Member", item.0.name),
                                    y: .value("Amount", item.1)
                                )
                                .foregroundStyle(ChillTheme.accent)
                            }
                            .id(debugCounter)
                            .frame(height: 200)
                        }
                    } else {
                        GroupBox(label: Text("By Payer").font(.headline).foregroundColor(ChillTheme.darkText)) {
                            Text("Not enough data yet – start adding expenses to see payer insights.")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .frame(maxWidth: .infinity, minHeight: 80)
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
            print("🟢 [AnalyticsView] onAppear — setting up observers")
            recomputeAnalytics()
            setupReactiveRefresh()
        }
    }

    // MARK: - Logic
    private func recomputeAnalytics() {
        debugCounter += 1

        // --- Direct (friend) expenses involving group members ---
        let directExpenses = friendsVM.directExpenses.filter { exp in
            exp.participants.contains(where: { group.members.contains($0) })
        }

        // --- Combine group + direct ---
        allExpensesForAnalytics = (group.expenses + directExpenses)
            .filter { $0.amount.isFinite && $0.amount >= 0 }

        // --- Global combination across all groups + all friends ---
        let allGroupExpenses = groupVM.groups.flatMap { $0.expenses }
        globalExpenses = (allGroupExpenses + friendsVM.directExpenses)
            .filter { $0.amount.isFinite && $0.amount >= 0 }

        print("""
        ✅ [AnalyticsView] recompute #\(debugCounter)
        - groupExpenses: \(group.expenses.count)
        - directExpenses (matching group): \(directExpenses.count)
        - allExpensesForAnalytics: \(allExpensesForAnalytics.count)
        - globalExpenses total: \(globalExpenses.count)
        """)
    }

    private func setupReactiveRefresh() {
        refreshCancellable?.cancel()

        let sources: [AnyPublisher<String, Never>] = [
            groupVM.$groups.map { _ in "groupVM.groups" }.eraseToAnyPublisher(),
            friendsVM.$directExpenses.map { _ in "friendsVM.directExpenses" }.eraseToAnyPublisher(),
            friendsVM.$didUpdateExpenses.map { _ in "friendsVM.didUpdateExpenses" }.eraseToAnyPublisher()
        ]

        refreshCancellable = Publishers.MergeMany(sources)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { source in
                print("⚡️ [AnalyticsView] Triggered by \(source)")
                recomputeAnalytics()
            }

        print("🟣 [AnalyticsView] Combine observers attached")
    }
}
