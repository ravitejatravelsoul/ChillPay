import SwiftUI
import Charts
import Combine

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

// MARK: - Time Range Enum
enum AnalyticsTimeRange: String, CaseIterable, Identifiable {
    case overall = "Overall"
    case yearly = "Yearly"
    case monthly = "Monthly"
    case weekly = "Weekly"
    var id: String { rawValue }
}

struct GlobalAnalyticsView: View {
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

    @State private var combinedExpenses: [Expense] = []
    @State private var refreshCancellable: AnyCancellable?
    @State private var debugCounter = 0
    @State private var selectedRange: AnalyticsTimeRange = .overall

    // MARK: - Derived Metrics
    private var allUsers: [User] {
        Array(Set(groupVM.groups.flatMap { $0.members })) + Array(Set(friendsVM.friends))
    }

    private var currencySymbol: String {
        groupVM.groups.first?.currency.symbol ?? "$"
    }

    private var categoryTotals: [CategoryTotal] {
        var dict = [ExpenseCategory: Double]()
        for exp in combinedExpenses where exp.amount.isFinite && exp.amount > 0 {
            dict[exp.category, default: 0] += exp.amount
        }
        let array = dict.map { CategoryTotal(category: $0.key, total: $0.value) }
        return array.sorted { $0.total > $1.total }
    }

    private var memberTotals: [MemberTotal] {
        var dict = [User: Double]()
        for exp in combinedExpenses where exp.amount.isFinite && exp.amount > 0 {
            dict[exp.paidBy, default: 0] += exp.amount
        }
        let array = dict.map { MemberTotal(user: $0.key, total: $0.value) }
        return array.sorted { $0.total > $1.total }
    }

    private var totalSpent: Double {
        combinedExpenses.reduce(0) { $0 + max(0, $1.amount) }
    }

    private var averagePerMember: Double {
        guard !allUsers.isEmpty else { return 0 }
        return totalSpent / Double(allUsers.count)
    }

    // MARK: - View
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Global Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    // Filter Picker
                    Picker("Range", selection: $selectedRange) {
                        ForEach(AnalyticsTimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedRange) { _, _ in
                        recomputeAnalytics()
                    }

                    // Summary Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Total spent: \(currencySymbol)\(String(format: "%.2f", totalSpent))").foregroundColor(.white)
                        Text("Total expenses: \(combinedExpenses.count)").foregroundColor(.white)
                        Text("Unique members: \(allUsers.count)").foregroundColor(.white)
                        Text("Average per member: \(currencySymbol)\(String(format: "%.2f", averagePerMember))").foregroundColor(.white)
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
                            .frame(height: 200)
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
                            .frame(height: 200)
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
        .onAppear {
            print("🟢 [GlobalAnalyticsView] onAppear – attaching observers")
            recomputeAnalytics()
            setupReactiveRefresh()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Logic
    private func recomputeAnalytics() {
        debugCounter += 1
        let now = Date()
        let calendar = Calendar.current

        let groupExpenses = groupVM.groups.flatMap { $0.expenses }
        let directExpenses = friendsVM.directExpenses
        var merged = (groupExpenses + directExpenses)
            .filter { $0.amount.isFinite && $0.amount >= 0 }

        // ⏱ Filter by selected time range
        switch selectedRange {
        case .overall:
            break
        case .yearly:
            merged = merged.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        case .monthly:
            merged = merged.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .weekly:
            merged = merged.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        }

        combinedExpenses = merged

        print("""
        ✅ [GlobalAnalyticsView] recompute #\(debugCounter)
        - Range: \(selectedRange.rawValue)
        - groupExpenses: \(groupExpenses.count)
        - directExpenses: \(directExpenses.count)
        - totalCombined (filtered): \(merged.count)
        - totalSpent: \(String(format: "%.2f", totalSpent))
        """)
    }

    private func setupReactiveRefresh() {
        refreshCancellable?.cancel()

        refreshCancellable = Publishers.Merge3(
            groupVM.$groups.map { _ in "groupVM.groups" },
            friendsVM.$directExpenses.map { _ in "friendsVM.directExpenses" },
            friendsVM.$didUpdateExpenses.map { _ in "friendsVM.didUpdateExpenses" }
        )
        .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
        .sink { source in
            print("⚡️ [GlobalAnalyticsView] Triggered by \(source)")
            recomputeAnalytics()
        }

        print("🟣 [GlobalAnalyticsView] Combine observers attached")
    }
}
