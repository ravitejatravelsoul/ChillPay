import SwiftUI

/// View used to edit an existing group's name and membership.  Members can
/// be added or removed.  Removing a member will also remove any expenses
/// that reference that user.
struct EditGroupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    var group: Group
    
    @State private var name: String
    @State private var memberNames: [String]
    @State private var isPublic: Bool
    @State private var budgetString: String
    @State private var selectedCurrency: Currency
    @State private var selectedColorName: String
    @State private var selectedIconName: String
    
    init(group: Group, groupVM: GroupViewModel) {
        self.group = group
        self.groupVM = groupVM
        _name = State(initialValue: group.name)
        let initialMembers = group.members.map { $0.name }
        _memberNames = State(initialValue: initialMembers.isEmpty ? [""] : initialMembers)
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
                    ForEach(memberNames.indices, id: \.self) { idx in
                        HStack {
                            TextField("Member Name", text: $memberNames[idx])
                            if memberNames.count > 1 {
                                Button(action: { memberNames.remove(at: idx) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    Button(action: { memberNames.append("") }) {
                        Label("Add Member", systemImage: "plus.circle")
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
                              memberNames.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty })
                }
            }
        }
    }
    
    /// Persist changes to the group.  This function computes which members
    /// have been removed and ensures any associated expenses are dropped.
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedMembers = memberNames.map { $0.trimmingCharacters(in: .whitespaces) }
        let filteredNames = trimmedMembers.filter { !$0.isEmpty }
        
        // Build updated member objects.  Reuse existing users if the name matches.
        var updatedMembers: [User] = []
        for userName in filteredNames {
            if let existing = group.members.first(where: { $0.name == userName }) {
                updatedMembers.append(existing)
            } else {
                updatedMembers.append(User(id: UUID(), name: userName))
            }
        }
        
        // Determine which members were removed compared to the original list
        let removedUsers = group.members.filter { original in
            !filteredNames.contains(where: { $0 == original.name })
        }
        // Remove expenses referencing removed users
        for removed in removedUsers {
            groupVM.removeMember(removed, from: group)
        }
        
        // Retrieve the latest version of the group from the view model
        var updatedGroup = groupVM.groups.first(where: { $0.id == group.id }) ?? group
        // Determine if the name changed and log it separately
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
            groupVM.logActivity(for: group.id, text: "Changed currency from \(oldCurrency.code) to \(selectedCurrency.code)")
        }
        // Update colour
        if updatedGroup.colorName != selectedColorName {
            updatedGroup.colorName = selectedColorName
            groupVM.logActivity(for: group.id, text: "Changed colour to \(selectedColorName)")
        }
        // Update icon
        if updatedGroup.iconName != selectedIconName {
            updatedGroup.iconName = selectedIconName
            groupVM.logActivity(for: group.id, text: "Changed icon to \(selectedIconName)")
        }
        // Update members
        updatedGroup.members = updatedMembers
        groupVM.updateGroup(updatedGroup)
        presentationMode.wrappedValue.dismiss()
    }
}
