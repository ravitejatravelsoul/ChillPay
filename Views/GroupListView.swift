import SwiftUI

struct GroupListView: View {
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel

    @State private var showingAddGroup = false

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(alignment: .leading) {
                HStack {
                    Text("Groups")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ChillTheme.darkText)
                    Spacer()
                    Button(action: { showingAddGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ChillTheme.accent)
                            .shadow(color: ChillTheme.lightShadow, radius: 4)
                    }
                    .accessibilityLabel("Add Group")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if groupVM.groups.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 56))
                            .foregroundColor(ChillTheme.softGray)
                        Text("No groups yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to create your first group.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(groupVM.groups) { group in
                                // FIX: Use correct argument order/labels for GroupDetailView!
                                NavigationLink(destination: GroupDetailView(groupVM: groupVM, friendsVM: friendsVM, group: group)) {
                                    GroupCardView(group: group)
                                        .padding(.horizontal)
                                        .padding(.vertical, 2)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView(groupVM: groupVM, friendsVM: friendsVM)
            }
        }
    }
}

struct GroupCardView: View {
    let group: Group

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(group.colorName))
                    .frame(width: 48, height: 48)
                Image(systemName: group.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ChillTheme.darkText)
                if let budget = group.budget {
                    Text("Budget: \(group.currency.symbol)\(String(format: "%.2f", budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(ChillTheme.softGray)
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(ChillTheme.cornerRadius)
        .shadow(color: ChillTheme.lightShadow, radius: ChillTheme.shadowRadius, x: 0, y: 2)
    }
}
