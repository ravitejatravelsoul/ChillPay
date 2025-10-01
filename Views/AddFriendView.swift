import SwiftUI

struct AddFriendView: View {
    @ObservedObject var friendsVM: FriendsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var emailOrUsername = ""
    @State private var inviteSent = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Add Friend")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Add by email or username")
                            .font(.headline)
                            .foregroundColor(.gray)

                        TextField("Email or Username", text: $emailOrUsername)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .foregroundColor(.primary)

                        if let msg = errorMsg {
                            Text(msg)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.top, 2)
                        }

                        Button(action: {
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
                        }) {
                            HStack {
                                Spacer()
                                Text("Add Friend")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(emailOrUsername.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.green)
                            .cornerRadius(14)
                        }
                        .disabled(emailOrUsername.trimmingCharacters(in: .whitespaces).isEmpty)

                        if inviteSent {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Invite sent!")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(28)
                .padding(.horizontal, 24)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}
