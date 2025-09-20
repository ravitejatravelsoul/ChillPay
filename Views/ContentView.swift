import SwiftUI

struct ContentView: View {
    @StateObject var groupVM = GroupViewModel()
    var body: some View {
        NavigationView {
            GroupListView()
                .environmentObject(groupVM)
                .navigationTitle("Groups")
        }
    }
}
