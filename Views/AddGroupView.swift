import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel

    @State private var name: String = ""
    @State private var memberNames: [String] = [""]
    @State private var isPublic: Bool = false
    @State private var budgetString: String = ""
    @State private var selectedCurrency: Currency = .usd
    @State private var selectedColorName: String = "blue"
    @State private var selectedIconName: String = "person.3.fill"

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
            .navigationTitle("New Group")
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

    /// Persist the new group and dismiss.
    private func save() {
        let trimmedNames = memberNames
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let members = trimmedNames.map { nameStr in
            User(id: UUID(), name: nameStr)
        }
        let budgetValue: Double? = Double(budgetString.trimmingCharacters(in: .whitespaces))
        let group = Group(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            members: members,
            expenses: [],
            isPublic: isPublic,
            budget: budgetValue,
            activity: [],
            currency: selectedCurrency,
            colorName: selectedColorName,
            iconName: selectedIconName,
            adjustments: []
        )
        groupVM.addGroup(group)
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
