import SwiftUI

/// Root view for ChillPay.  Creates a single `GroupViewModel` and injects
/// it into the `GroupListView` for the remainder of the application.
struct ContentView: View {
    @StateObject private var groupVM = GroupViewModel()
    
    var body: some View {
        NavigationView {
            GroupListView(groupVM: groupVM)
        }
    }
}
