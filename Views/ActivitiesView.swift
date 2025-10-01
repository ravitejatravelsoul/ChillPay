import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var groupVM: GroupViewModel

    // Combine activity from all groups, most recent first
    private var allActivities: [Activity] {
        groupVM.groups.flatMap { $0.activity }
            .sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        NavigationView {
            ZStack {
                ChillTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Use environment injection for GlobalAnalyticsView, NOT initializer
                        GlobalAnalyticsView()
                            .environmentObject(groupVM)
                            .padding(.horizontal)

                        Divider()
                            .background(Color.white.opacity(0.3))

                        Text("Activity Timeline")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        if allActivities.isEmpty {
                            Text("No activities yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)
                        } else {
                            ForEach(allActivities) { activity in
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
    }
}

// Simple row for one activity entry
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
