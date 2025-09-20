import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var groupVM: GroupViewModel
    @State private var name = ""
    @State private var memberNames: [String] = [""]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Group Name", text: $name)
                Section(header: Text("Members")) {
                    ForEach(memberNames.indices, id: \.self) { idx in
                        HStack {
                            TextField("Member Name", text: $memberNames[idx])
                            if memberNames.count > 1 {
                                Button(action: { memberNames.remove(at: idx) }) {
                                    Image(systemName: "minus.circle")
                                }
                            }
                        }
                    }
                    Button("Add Member") {
                        memberNames.append("")
                    }
                }
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let members = memberNames
                            .filter { !$0.isEmpty }
                            .map { User(id: UUID(), name: $0) }
                        let newGroup = Group(id: UUID(), name: name, members: members, expenses: [])
                        groupVM.addGroup(newGroup)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
