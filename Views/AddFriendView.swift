import SwiftUI

struct AddFriendView: View {
    @ObservedObject var friendsVM: FriendsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var emailOrUsername = ""
    @State private var inviteSent = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add by email or username")) {
                    TextField("Email or Username", text: $emailOrUsername)
                        .keyboardType(.emailAddress)
                    if let msg = errorMsg {
                        Text(msg)
                            .foregroundColor(.red)
                    }
                    Button("Add Friend") {
                        friendsVM.addOrInviteFriend(identifier: emailOrUsername) { result in
                            switch result {
                            case .success(let added):
                                inviteSent = !added
                                errorMsg = nil
                                if added { presentationMode.wrappedValue.dismiss() }
                            case .failure(let error):
                                errorMsg = error.localizedDescription
                            }
                        }
                    }
                    .disabled(emailOrUsername.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if inviteSent {
                    Section {
                        Text("Invite sent!").foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
