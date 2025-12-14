import SwiftUI

struct AddFriendView: View {
    @ObservedObject var friendsVM: FriendsViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var email = ""
    @State private var inviteSent = false
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Friend")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)

                    Text("Add by email")
                        .font(.headline)
                        .foregroundColor(ChillTheme.darkText.opacity(0.7))

                    ChillTextField(title: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if let msg = errorMsg {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }

                    ChillPrimaryButton(
                        title: "Add Friend",
                        isDisabled: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        systemImage: "person.badge.plus"
                    ) {
                        addFriend()
                    }

                    if inviteSent {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ChillTheme.accent)
                            Text("Invite sent!")
                                .foregroundColor(ChillTheme.accent)
                                .fontWeight(.semibold)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(20)
                .shadow(color: ChillTheme.lightShadow, radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(ChillTheme.accent)
            }
        }
    }

    private func addFriend() {
        inviteSent = false
        errorMsg = nil

        friendsVM.addOrInviteFriend(email: email) { result in
            switch result {
            case .success(let added):
                inviteSent = !added
                errorMsg = nil
                if added {
                    presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                print("Add friend error: \(error.localizedDescription)")
                errorMsg = "Couldn’t add friend. Please check the email and try again."
            }
        }
    }
}
