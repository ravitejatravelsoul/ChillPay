import SwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

struct GroupSettingsSheet: View {
    let groupVM: GroupViewModel
    let friendsVM: FriendsViewModel
    @State var group: Group
    @State var simplifyDebts: Bool
    let onUpdateSimplify: (Bool) -> Void
    let onDeleteGroup: () -> Void
    let onLeaveGroup: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEditGroup = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showQR = false
    @State private var inviteLink: String = ""
    @State private var qrImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                ChillTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        editGroupButton
                        membersSection
                        addMembersSection
                        inviteSection
                        exportSection
                        balancesSection
                        settlementsSection
                        simplifyToggleSection
                        destructiveActions
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                            .foregroundColor(.white)
                    }
                }
            }
            .onChange(of: simplifyDebts) { newValue, _ in
                onUpdateSimplify(newValue)
            }
            .sheet(isPresented: $showEditGroup) {
                EditGroupView(group: group, groupVM: groupVM, friendsVM: friendsVM)
            }
        }
    }

    // MARK: - Subsections

    private var headerSection: some View {
        Text("Group Settings")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 20)
    }

    private var editGroupButton: some View {
        Button(action: { showEditGroup = true }) {
            Label("Edit Group Info", systemImage: "pencil")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(18)
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members")
                .font(.headline)
                .foregroundColor(.white)
            ForEach(group.members) { member in
                HStack {
                    Circle()
                        .fill(Color.avatarColor(for: member))
                        .frame(width: 28, height: 28)
                        .overlay(Text(member.initials).font(.caption).foregroundColor(.white))
                    Text(member.id == FriendsViewModel.shared.currentUser?.id ? "Me" : member.name)
                        .foregroundColor(.white)
                    Spacer()
                    if group.members.count > 1 && member.id != FriendsViewModel.shared.currentUser?.id {
                        Button {
                            groupVM.removeMember(member, from: group)
                            group = groupVM.groups.first(where: { $0.id == group.id }) ?? group
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var addMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Members")
                .font(.headline)
                .foregroundColor(.white)
            let nonMembers = friendsVM.friends.filter { f in
                !group.members.contains(where: { $0.id == f.id })
            }
            if nonMembers.isEmpty {
                Text("No more friends to add.")
                    .foregroundColor(.gray)
            } else {
                ForEach(nonMembers) { friend in
                    Button {
                        groupVM.addMember(friend, to: group)
                        group = groupVM.groups.first(where: { $0.id == group.id }) ?? group
                    } label: {
                        HStack {
                            AvatarView(user: friend)
                                .frame(width: 24, height: 24)
                            Text(friend.name)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invite Link & QR")
                .font(.headline)
                .foregroundColor(.white)
            Button {
                inviteLink = groupVM.inviteLink(for: group)
                qrImage = groupVM.qrImage(for: inviteLink)
                showQR = true
            } label: {
                Label("Show Invite QR / Link", systemImage: "qrcode")
                    .foregroundColor(.white)
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showQR) {
                qrSheet
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var qrSheet: some View {
        VStack(spacing: 16) {
            if let qr = qrImage {
                Image(uiImage: qr)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            }
            Text(inviteLink)
                .font(.footnote)
                .foregroundColor(.white)
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(10)
            if let url = URL(string: inviteLink) {
                ShareLink(item: url) {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                }
            }
            Button("Dismiss") { showQR = false }
                .padding(.top)
        }
        .padding()
        .background(ChillTheme.background)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Group Data")
                .font(.headline)
                .foregroundColor(.white)
            Button {
                exportURL = groupVM.exportCSV(for: group)
                showExportSheet = true
            } label: {
                Label("Export as CSV", systemImage: "square.and.arrow.down")
                    .foregroundColor(.white)
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(10)
            }
            .fileExporter(
                isPresented: $showExportSheet,
                document: exportURL.map { CSVDocument(url: $0) },
                contentType: .commaSeparatedText,
                defaultFilename: "\(group.name)-expenses.csv"
            ) { _ in }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var balancesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balances")
                .font(.headline)
                .foregroundColor(.white)
            let balances = ExpenseViewModel(groupVM: groupVM).getBalances(for: group)
            ForEach(group.members, id: \.id) { user in
                let bal = balances[user] ?? 0
                HStack {
                    Text(user.name)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(bal < 0 ? "-" : "")\(group.currency.symbol)\(abs(bal), specifier: "%.2f")")
                        .foregroundColor(bal < 0 ? .red : .green)
                }
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var settlementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settlements")
                .font(.headline)
                .foregroundColor(.white)
            let settlements = ExpenseViewModel(groupVM: groupVM).getSettlement(for: group)
            if settlements.isEmpty {
                Text("Everyone is settled up!")
                    .foregroundColor(.green)
            } else {
                ForEach(Array(settlements.enumerated()), id: \.offset) { _, s in
                    Text("\(s.payer.name) pays \(s.payee.name) \(group.currency.symbol)\(String(format: "%.2f", s.amount))")
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var simplifyToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $simplifyDebts) {
                Text("Simplify Group Debts")
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding()
        .background(ChillTheme.card)
        .cornerRadius(18)
    }

    private var destructiveActions: some View {
        VStack(spacing: 12) {
            Button(role: .destructive, action: onDeleteGroup) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Group")
                }
                .foregroundColor(.red)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(12)
            }

            Button(role: .destructive, action: onLeaveGroup) {
                HStack {
                    Image(systemName: "figure.walk")
                    Text("Leave Group")
                }
                .foregroundColor(.red)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - CSVDocument for Export
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws {
        url = URL(fileURLWithPath: "")
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: url)
        return FileWrapper(regularFileWithContents: data)
    }
}
