import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel

    var body: some View {
        NavigationView {
            GroupListView(groupVM: groupVM, friendsVM: friendsVM)
        }
    }
}
