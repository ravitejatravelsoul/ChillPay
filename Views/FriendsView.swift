import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsVM: FriendsViewModel = FriendsViewModel.shared // Assume singleton or inject
    @State private var searchText = ""
    @State private var showAddFriendSheet = false
    @State private var selectedFriend: User?
    @State private var sortByOwesYou = false
    
    var filteredFriends: [User] {
        let list = friendsVM.friends
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search friends...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                }
                // Add friend and sort buttons
                HStack {
                    Button(action: { showAddFriendSheet = true }) {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }
                    Spacer()
                    Button(action: { sortByOwesYou.toggle(); friendsVM.sortByOwesYou(sort: sortByOwesYou) }) {
                        Image(systemName: sortByOwesYou ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                        Text(sortByOwesYou ? "Sort: Owes You" : "Sort: Name")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Pending invites
                if !friendsVM.pendingInvites.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Pending Invites")
                            .font(.headline)
                        ForEach(friendsVM.pendingInvites) { invite in
                            HStack {
                                Text(invite.email)
                                Spacer()
                                Text("Invited")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Friends list
                List {
                    ForEach(filteredFriends) { friend in
                        HStack {
                            AvatarView(user: friend)
                            VStack(alignment: .leading) {
                                Text(friend.name)
                                if let email = friend.email {
                                    Text(email).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            // Show net balance
                            let balance = friendsVM.balanceWith(friend: friend)
                            Text(friendsVM.balanceString(balance, friend: friend))
                                .foregroundColor(friendsVM.balanceColor(balance))
                                .font(.headline)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedFriend = friend }
                        .contextMenu {
                            Button("Remove Friend", role: .destructive) {
                                friendsVM.removeFriend(friend)
                            }
                        }
                    }
                }
                .refreshable { friendsVM.refreshFriends() }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFriendSheet = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendView(friendsVM: friendsVM)
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend, friendsVM: friendsVM)
            }
        }
    }
}
