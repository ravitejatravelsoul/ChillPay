import SwiftUI

struct GroupListView: View {
    @EnvironmentObject var groupVM: GroupViewModel
    @State private var showAddGroup = false

    var body: some View {
        List {
            ForEach(groupVM.groups) { group in
                NavigationLink(destination: ExpenseListView(groupVM: groupVM, group: group)) {
                    Text(group.name)
                }
            }
        }
        .toolbar {
            Button(action: { showAddGroup.toggle() }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupView()
                .environmentObject(groupVM)
        }
    }
}
