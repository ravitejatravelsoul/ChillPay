import SwiftUI
import Combine

struct ActivitiesView: View {
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

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
                            .background(Color.white.opacity(0.3))

                        // --- ACTIVITY TIMELINE ---
                        Text("Activity Timeline")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        if combinedActivities.isEmpty {
                            Text("No activities yet.")
                                .foregroundColor(.white.opacity(0.6))
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
            .preferredColorScheme(.dark)
        }
        .onAppear {
            print("🟢 [ActivitiesView] onAppear — setting up Combine updates")
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
            Activity(
                id: exp.id,
                text: "\(exp.paidBy.name) paid \(String(format: "%.2f", exp.amount)) for \(exp.title)",
                date: exp.date
            )
        }

        // 🔹 3. Combine & sort
        let merged = (groupActivities + friendActivities)
            .sorted(by: { $0.date > $1.date })

        combinedActivities = merged

        print("""
        ✅ [ActivitiesView] recompute #\(debugCounter)
        - groupActivities: \(groupActivities.count)
        - friendActivities: \(friendActivities.count)
        - totalCombined: \(merged.count)
        """)
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
            print("⚡️ [ActivitiesView] Triggered by \(source)")
            recomputeActivities()
        }

        print("🟣 [ActivitiesView] Combine observers attached")
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
                    .foregroundColor(.white)
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(8)
        .background(ChillTheme.card)
        .cornerRadius(8)
    }
}
