import SwiftUI

struct GlobalSettingsSheet: View {
    let groupVM: GroupViewModel?
    let friendsVM: FriendsViewModel?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                if let groupVM = groupVM {
                    Section(header: Text("Groups")) {
                        ForEach(groupVM.groups) { group in
                            Text(group.name)
                        }
                    }
                }
                if let friendsVM = friendsVM {
                    Section(header: Text("Friends")) {
                        ForEach(friendsVM.friends) { friend in
                            Text(friend.name)
                        }
                    }
                }
            }
            .navigationTitle("App Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
