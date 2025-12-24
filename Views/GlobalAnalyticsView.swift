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
    @ObservedObject private var currencyManager = CurrencyManager.shared

    @State private var combinedExpenses: [Expense] = []
    @State private var refreshCancellable: AnyCancellable?
    @State private var debugCounter = 0
    @State private var selectedRange: AnalyticsTimeRange = .overall

    // MARK: - Derived Metrics
    private var allUsers: [User] {
        Array(Set(groupVM.groups.flatMap { $0.members })) + Array(Set(friendsVM.friends))
    }

    private var categoryTotals: [CategoryTotal] {
        var dict = [ExpenseCategory: Double]()
        for exp in combinedExpenses where exp.amount.isFinite && exp.amount > 0 {
            // Determine currency of expense: use group's currency when groupID is present
            var convertedAmount = exp.amount
            if let gid = exp.groupID {
                // groupID is stored as UUID in Expense, while Group.id is a String.
                if let group = groupVM.groups.first(where: { $0.id == gid.uuidString }) {
                    convertedAmount = currencyManager.convert(amount: exp.amount, from: group.currency)
                }
            }
            dict[exp.category, default: 0] += convertedAmount
        }
        let array = dict.map { CategoryTotal(category: $0.key, total: $0.value) }
        return array.sorted { $0.total > $1.total }
    }

    private var memberTotals: [MemberTotal] {
        var dict = [User: Double]()
        for exp in combinedExpenses where exp.amount.isFinite && exp.amount > 0 {
            var convertedAmount = exp.amount
            if let gid = exp.groupID {
                if let group = groupVM.groups.first(where: { $0.id == gid.uuidString }) {
                    convertedAmount = currencyManager.convert(amount: exp.amount, from: group.currency)
                }
            }
            dict[exp.paidBy, default: 0] += convertedAmount
        }
        let array = dict.map { MemberTotal(user: $0.key, total: $0.value) }
        return array.sorted { $0.total > $1.total }
    }

    private var totalSpent: Double {
        combinedExpenses.reduce(0) { partial, exp in
            guard exp.amount.isFinite, exp.amount > 0 else { return partial }
            var converted = exp.amount
            if let gid = exp.groupID {
                if let group = groupVM.groups.first(where: { $0.id == gid.uuidString }) {
                    converted = currencyManager.convert(amount: exp.amount, from: group.currency)
                }
            }
            return partial + converted
        }
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
                        .foregroundColor(ChillTheme.darkText)
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
                            .foregroundColor(ChillTheme.darkText)
                        Text("Total spent: \(currencyManager.format(amount: totalSpent))")
                            .foregroundColor(ChillTheme.darkText)
                        Text("Total expenses: \(combinedExpenses.count)")
                            .foregroundColor(ChillTheme.darkText)
                        Text("Unique members: \(allUsers.count)")
                            .foregroundColor(ChillTheme.darkText)
                        Text("Average per member: \(currencyManager.format(amount: averagePerMember))")
                            .foregroundColor(ChillTheme.darkText)
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(20)

                    // Category Chart
                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Category")
                                .font(.headline)
                                .foregroundColor(ChillTheme.darkText)
                            Chart(categoryTotals) { item in
                                BarMark(
                                    x: .value("Category", item.category.displayName),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(ChillTheme.accent)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(ChillTheme.card)
                        .cornerRadius(20)
                    } else {
                        // Empty state for category totals
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Category")
                                .font(.headline)
                                .foregroundColor(ChillTheme.darkText)
                            Text("Not enough data yet – start adding expenses to see category insights.")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .frame(maxWidth: .infinity, minHeight: 80)
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
                                .foregroundColor(ChillTheme.darkText)
                            Chart(memberTotals) { item in
                                BarMark(
                                    x: .value("Member", item.user.name),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(ChillTheme.accent)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(ChillTheme.card)
                        .cornerRadius(20)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Payer")
                                .font(.headline)
                                .foregroundColor(ChillTheme.darkText)
                            Text("Not enough data yet – start adding expenses to see payer insights.")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .frame(maxWidth: .infinity, minHeight: 80)
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
            #if DEBUG
            print("🟢 [GlobalAnalyticsView] onAppear – attaching observers")
            #endif
            recomputeAnalytics()
            setupReactiveRefresh()
        }
        // Do not force dark mode – use system appearance instead
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

        #if DEBUG
        print("""
        ✅ [GlobalAnalyticsView] recompute #\(debugCounter)
        - Range: \(selectedRange.rawValue)
        - groupExpenses: \(groupExpenses.count)
        - directExpenses: \(directExpenses.count)
        - totalCombined (filtered): \(merged.count)
        - totalSpent: \(String(format: "%.2f", totalSpent))
        """)
        #endif
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
            #if DEBUG
            print("⚡️ [GlobalAnalyticsView] Triggered by \(source)")
            #endif
            recomputeAnalytics()
        }

        #if DEBUG
        print("🟣 [GlobalAnalyticsView] Combine observers attached")
        #endif
    }
}
