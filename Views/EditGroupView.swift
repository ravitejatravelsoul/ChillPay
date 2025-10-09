import SwiftUI

struct EditGroupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel
    var group: Group

    @State private var name: String
    @State private var selectedMemberIDs: Set<String>
    @State private var isPublic: Bool
    @State private var budgetString: String
    @State private var selectedCurrency: Currency
    @State private var selectedColorName: String
    @State private var selectedIconName: String

    init(group: Group, groupVM: GroupViewModel, friendsVM: FriendsViewModel) {
        self.group = group
        self.groupVM = groupVM
        self.friendsVM = friendsVM
        _name = State(initialValue: group.name)
        _selectedMemberIDs = State(initialValue: Set(group.members.map { $0.id })) // <--- String now
        _isPublic = State(initialValue: group.isPublic)
        if let budget = group.budget {
            _budgetString = State(initialValue: String(format: "%.2f", budget))
        } else {
            _budgetString = State(initialValue: "")
        }
        _selectedCurrency = State(initialValue: group.currency)
        _selectedColorName = State(initialValue: group.colorName)
        _selectedIconName = State(initialValue: group.iconName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Name")) {
                    TextField("Enter name", text: $name)
                }
                Section(header: Text("Members")) {
                    if friendsVM.friends.isEmpty {
                        Text("No friends available. Add friends to add them to groups.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(friendsVM.friends) { friend in
                            Button(action: {
                                if selectedMemberIDs.contains(friend.id) {
                                    selectedMemberIDs.remove(friend.id)
                                } else {
                                    selectedMemberIDs.insert(friend.id)
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(friend.name)
                                        if let email = friend.email, !email.isEmpty {
                                            Text(email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedMemberIDs.contains(friend.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                Section(header: Text("Settings")) {
                    Toggle("Public Group", isOn: $isPublic)
                    TextField("Budget (optional)", text: $budgetString)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.displayName) (\(currency.symbol))").tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    VStack(alignment: .leading) {
                        Text("Colour")
                            .font(.subheadline)
                        HStack {
                            ForEach(["blue", "green", "orange", "red", "purple", "pink", "yellow", "teal"], id: \.self) { name in
                                Circle()
                                    .fill(color(for: name))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColorName == name ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColorName = name
                                    }
                            }
                        }
                        Text("Icon")
                            .font(.subheadline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(["person.3.fill", "airplane", "car.fill", "cart.fill", "house.fill", "gift.fill", "fork.knife", "music.note.list", "briefcase.fill", "bag.fill"], id: \.self) { icon in
                                    Image(systemName: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(selectedIconName == icon ? Color.primary : Color.gray.opacity(0.3), lineWidth: selectedIconName == icon ? 2 : 1)
                                        )
                                        .onTapGesture {
                                            selectedIconName = icon
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              selectedMemberIDs.isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let updatedMembers = friendsVM.friends.filter { selectedMemberIDs.contains($0.id) }

        // Remove expenses referencing removed users
        let removedUsers = group.members.filter { original in
            !updatedMembers.contains(where: { $0.id == original.id })
        }
        for removed in removedUsers {
            groupVM.removeMember(removed, from: group)
        }

        // Retrieve the latest version of the group from the view model
        var updatedGroup = groupVM.groups.first(where: { $0.id == group.id }) ?? group

        // Update name and log if changed
        if updatedGroup.name != trimmedName {
            groupVM.renameGroup(updatedGroup, newName: trimmedName)
            updatedGroup.name = trimmedName
        }

        // Compute budget value from text
        let trimmedBudget = budgetString.trimmingCharacters(in: .whitespaces)
        let budgetValue = Double(trimmedBudget)
        updatedGroup.budget = budgetValue

        // Update public flag
        if updatedGroup.isPublic != isPublic {
            updatedGroup.isPublic = isPublic
            let state = isPublic ? "public" : "private"
            groupVM.logActivity(for: group.id, text: "Changed group visibility to \(state)")
        }

        // Update currency if it changed
        if updatedGroup.currency != selectedCurrency {
            let oldCurrency = updatedGroup.currency
            updatedGroup.currency = selectedCurrency
            groupVM.logActivity(
                for: group.id,
                text: "Changed currency from \(oldCurrency.rawValue.uppercased()) to \(selectedCurrency.rawValue.uppercased())"
            )
        }

        // Update colour and icon if changed
        if updatedGroup.colorName != selectedColorName {
            updatedGroup.colorName = selectedColorName
            groupVM.logActivity(for: group.id, text: "Changed colour to \(selectedColorName)")
        }
        if updatedGroup.iconName != selectedIconName {
            updatedGroup.iconName = selectedIconName
            groupVM.logActivity(for: group.id, text: "Changed icon to \(selectedIconName)")
        }

        // Update members
        updatedGroup.members = updatedMembers
        groupVM.updateGroup(updatedGroup)
        presentationMode.wrappedValue.dismiss()
    }

    // Helper to get a Color from a color name string
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
