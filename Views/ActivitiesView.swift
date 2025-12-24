import SwiftUI
import Combine

struct ActivitiesView: View {
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

    /// ✅ FIX: Don't rely on EnvironmentObject (can be missing and crash).
    /// CurrencyManager is a singleton, so observe it directly.
    @ObservedObject private var currencyManager = CurrencyManager.shared

    @State private var combinedActivities: [Activity] = []
    @State private var refreshCancellable: AnyCancellable?
    @State private var debugCounter = 0

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                ChillTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // --- GLOBAL ANALYTICS SECTION ---
                        GlobalAnalyticsView()
                            .environmentObject(groupVM)
                            .padding(.horizontal)

                        Divider()
                            .background(ChillTheme.softGray)

                        // --- ACTIVITY TIMELINE ---
                        Text("Activity Timeline")
                            .font(.title2)
                            .bold()
                            .foregroundColor(ChillTheme.darkText)
                            .padding(.horizontal)

                        if combinedActivities.isEmpty {
                            Text("No activities yet – add some expenses to get started.")
                                .foregroundColor(ChillTheme.darkText.opacity(0.6))
                                .padding(.horizontal)
                        } else {
                            ForEach(combinedActivities) { activity in
                                ActivityRowView(activity: activity)
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Activities")
        }
        .onAppear {
            #if DEBUG
            print("🟢 [ActivitiesView] onAppear — setting up Combine updates")
            #endif
            recomputeActivities()
            setupReactiveRefresh()
        }
    }

    // MARK: - Recompute Combined Activities
    private func recomputeActivities() {
        debugCounter += 1

        // 🔹 1. Group activities
        let groupActivities = groupVM.groups.flatMap { $0.activity }

        // 🔹 2. Direct expenses → Convert into Activity entries
        let friendActivities: [Activity] = friendsVM.directExpenses.map { exp in
            // Format the direct expense amount using the user's currency
            let formattedAmount = currencyManager.format(amount: exp.amount)
            return Activity(
                id: exp.id,
                text: "\(exp.paidBy.name) paid \(formattedAmount) for \(exp.title)",
                date: exp.date
            )
        }

        // 🔹 3. Combine & sort
        let merged = (groupActivities + friendActivities)
            .sorted(by: { $0.date > $1.date })

        combinedActivities = merged

        #if DEBUG
        print("""
        ✅ [ActivitiesView] recompute #\(debugCounter)
        - groupActivities: \(groupActivities.count)
        - friendActivities: \(friendActivities.count)
        - totalCombined: \(merged.count)
        """)
        #endif
    }

    // MARK: - Combine Reactive Updates
    private func setupReactiveRefresh() {
        refreshCancellable?.cancel()

        refreshCancellable = Publishers.Merge3(
            groupVM.$groups.map { _ in "groupVM.groups" },
            friendsVM.$directExpenses.map { _ in "friendsVM.directExpenses" },
            friendsVM.$didUpdateExpenses.map { _ in "friendsVM.didUpdateExpenses" }
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { source in
            #if DEBUG
            print("⚡️ [ActivitiesView] Triggered by \(source)")
            #endif
            recomputeActivities()
        }

        #if DEBUG
        print("🟣 [ActivitiesView] Combine observers attached")
        #endif
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    var activity: Activity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.text)
                    .font(.body)
                    .foregroundColor(ChillTheme.darkText)
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundColor(ChillTheme.darkText.opacity(0.6))
            }
            Spacer()
        }
        .padding(8)
        .background(ChillTheme.card)
        .cornerRadius(8)
    }
}
