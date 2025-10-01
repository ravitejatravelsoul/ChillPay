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
    @State private var errorMsg: String?

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Create New Group")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 20) {
                        // Group Name
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        ZStack(alignment: .leading) {
                            if name.isEmpty {
                                Text("Enter name")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $name)
                                .textFieldStyle(ChillTextFieldStyle())
                        }

                        // Members
                        Text("Members")
                            .font(.headline)
                            .foregroundColor(.white)
                        VStack(spacing: 8) {
                            ForEach(memberNames.indices, id: \.self) { idx in
                                HStack {
                                    ZStack(alignment: .leading) {
                                        if memberNames[idx].isEmpty {
                                            Text("Member Name")
                                                .foregroundColor(.white.opacity(0.5))
                                                .padding(.leading, 18)
                                        }
                                        TextField("", text: $memberNames[idx])
                                            .textFieldStyle(ChillTextFieldStyle())
                                    }
                                    if memberNames.count > 1 {
                                        Button(action: { memberNames.remove(at: idx) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            Button(action: { memberNames.append("") }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Member")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding(.vertical, 4)
                                .foregroundColor(.green)
                            }
                        }

                        // Settings
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isPublic) {
                                Text("Public Group")
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .green))

                            ZStack(alignment: .leading) {
                                if budgetString.isEmpty {
                                    Text("Budget (optional)")
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(.leading, 18)
                                }
                                TextField("", text: $budgetString)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(ChillTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Currency")
                                    .foregroundColor(.white)
                                Picker("", selection: $selectedCurrency) {
                                    ForEach(Currency.allCases) { currency in
                                        Text("\(currency.displayName) (\(currency.symbol))")
                                            .foregroundColor(.white)
                                            .tag(currency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }

                            // Color Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Colour")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                HStack {
                                    ForEach(["blue", "green", "orange", "red", "purple", "pink", "yellow", "teal"], id: \.self) { name in
                                        Circle()
                                            .fill(color(for: name))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColorName == name ? Color.green : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                selectedColorName = name
                                            }
                                    }
                                }
                            }
                            // Icon Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Icon")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(["person.3.fill", "airplane", "car.fill", "cart.fill", "house.fill", "gift.fill", "fork.knife", "music.note.list", "briefcase.fill", "bag.fill"], id: \.self) { icon in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedIconName == icon ? Color.green : Color.gray.opacity(0.4), lineWidth: selectedIconName == icon ? 2.5 : 1)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(selectedIconName == icon ? Color.green.opacity(0.18) : Color.clear)
                                                    )
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: icon)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.white)
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

                    Button(action: {
                        save()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(isSaveDisabled ? ChillTheme.softGray.opacity(0.2) : ChillTheme.accent)
                        .cornerRadius(14)
                    }
                    .disabled(isSaveDisabled)
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
        name.trimmingCharacters(in: .whitespaces).isEmpty ||
        memberNames.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
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
            adjustments: [],
            simplifyDebts: false
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
