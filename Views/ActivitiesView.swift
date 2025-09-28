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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GlobalAnalyticsView()
                        .environmentObject(groupVM)
                        .padding(.horizontal)

                    Divider()

                    Text("Activity Timeline")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    if allActivities.isEmpty {
                        Text("No activities yet.")
                            .foregroundColor(.secondary)
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
            .navigationTitle("Activities")
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
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
