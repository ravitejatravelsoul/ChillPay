import SwiftUI

@main
struct ChillPayApp: App {
    @StateObject private var groupVM = GroupViewModel()
    @StateObject private var friendsVM = FriendsViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(groupVM)
                .environmentObject(friendsVM)
        }
    }
}
