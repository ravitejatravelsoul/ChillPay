import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel

    @State private var name: String = ""
    @State private var selectedMembers: Set<User> = []
    @State private var isPublic: Bool = false
    @State private var budgetString: String = ""
    @State private var selectedCurrency: Currency = .usd
    @State private var selectedColorName: String = "blue"
    @State private var selectedIconName: String = "person.3.fill"
    @State private var errorMsg: String?

    private var selectableMembers: [User] {
        var list: [User] = []
        // Use the injected view model instance, not the singleton, to avoid cases
        // where the singleton briefly becomes nil during auth refresh.
        if let me = friendsVM.currentUser {
            list.append(me)
        }
        let filteredFriends = friendsVM.friends.filter { $0.id != friendsVM.currentUser?.id }
        list.append(contentsOf: filteredFriends)
        return list
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Create New Group")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        ZStack(alignment: .leading) {
                            if name.isEmpty {
                                Text("Enter name")
                                    .foregroundColor(ChillTheme.darkText.opacity(0.5))
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $name)
                                .textFieldStyle(ChillTextFieldStyle())
                        }

                        Text("Members")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        VStack(spacing: 8) {
                            ForEach(selectableMembers) { member in
                                Button(action: {
                                    if selectedMembers.contains(member) {
                                        selectedMembers.remove(member)
                                    } else {
                                        selectedMembers.insert(member)
                                    }
                                }) {
                                    HStack {
                                        AvatarView(user: member)
                                            .frame(width: 30, height: 30)
                                        Text(member.id == friendsVM.currentUser?.id ? "Me" : member.name)
                                            .foregroundColor(ChillTheme.darkText)
                                        Spacer()
                                        if selectedMembers.contains(member) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(ChillTheme.accent)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isPublic) {
                                Text("Public Group")
                                    .foregroundColor(ChillTheme.darkText)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ChillTheme.accent))

                            ZStack(alignment: .leading) {
                                if budgetString.isEmpty {
                                    Text("Budget (optional)")
                                        .foregroundColor(ChillTheme.darkText.opacity(0.5))
                                        .padding(.leading, 18)
                                }
                                TextField("", text: $budgetString)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(ChillTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Currency")
                                    .foregroundColor(ChillTheme.darkText)
                                Picker("", selection: $selectedCurrency) {
                                    ForEach(Currency.allCases) { currency in
                                        Text("\(currency.displayName) (\(currency.symbol))")
                                            .foregroundColor(ChillTheme.darkText)
                                            .tag(currency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Colour")
                                    .font(.subheadline)
                                    .foregroundColor(ChillTheme.darkText)
                                HStack {
                                    ForEach(["blue", "green", "orange", "red", "purple", "pink", "yellow", "teal"], id: \.self) { name in
                                        Circle()
                                            .fill(color(for: name))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColorName == name ? ChillTheme.accent : Color.clear, lineWidth: selectedColorName == name ? 2 : 1)
                                            )
                                            .onTapGesture {
                                                selectedColorName = name
                                            }
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Icon")
                                    .font(.subheadline)
                                    .foregroundColor(ChillTheme.darkText)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["person.3.fill", "airplane", "car.fill", "cart.fill", "house.fill", "gift.fill", "fork.knife", "music.note.list", "briefcase.fill", "bag.fill"], id: \.self) { icon in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedIconName == icon ? ChillTheme.accent : Color.gray.opacity(0.4), lineWidth: selectedIconName == icon ? 2.5 : 1)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(selectedIconName == icon ? ChillTheme.accent.opacity(0.18) : Color.clear)
                                                    )
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: icon)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(ChillTheme.darkText)
                                            }
                                            .padding(2)
                                            .onTapGesture {
                                                selectedIconName = icon
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let error = errorMsg {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 2)
                    }

                    ChillPrimaryButton(title: "Save", isDisabled: isSaveDisabled) {
                        save()
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
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty || selectedMembers.isEmpty
    }

    private func save() {
        var groupMembers = selectedMembers
        if let me = friendsVM.currentUser {
            groupMembers.insert(me)
        }
        let budgetValue: Double? = Double(budgetString.trimmingCharacters(in: .whitespaces))
        let group = Group(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            members: Array(groupMembers),
            expenses: [],
            isPublic: isPublic,
            budget: budgetValue,
            activity: [],
            currency: selectedCurrency,
            colorName: selectedColorName,
            iconName: selectedIconName,
            adjustments: [],
            simplifyDebts: false
        )
        groupVM.addGroup(group)
        presentationMode.wrappedValue.dismiss()
    }

    private func color(for name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .gray
        }
    }
}
