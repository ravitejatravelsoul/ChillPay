import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var groupVM: GroupViewModel
    @ObservedObject var friendsVM: FriendsViewModel
    @State var group: Group
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense? = nil
    @State private var showSettings = false

    // Sync group if it changes in the ViewModel
    private func syncGroup() {
        if let updated = groupVM.groups.first(where: { $0.id == group.id }) {
            group = updated
        }
    }

    var body: some View {
        ZStack {
            // Use the global theme background rather than a dark gradient for a light mode appearance
            ChillTheme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HeaderCard(group: group)
                    ExpensesSwipeCard(
                        group: group,
                        groupVM: groupVM,
                        onEdit: { expense in editingExpense = expense },
                        onDelete: { expense in deleteExpense(expense) }
                    )
                    ActivityCard(group: group)
                }
                .padding(.horizontal)
                .padding(.bottom, 110)
                .padding(.top, 16)
            }
            .onAppear { syncGroup() }
            .onReceive(groupVM.$groups) { _ in syncGroup() }

            // Floating Add Expense Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddExpense = true }) {
                        ZStack {
                            Circle()
                                .fill(ChillTheme.accent)
                                .frame(width: 60, height: 60)
                                .shadow(color: ChillTheme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 24)
                    .padding(.trailing, 24)
                    .accessibilityLabel("Add Expense")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: group, groupVM: groupVM)
        }
        .sheet(item: $editingExpense) { exp in
            AddExpenseView(group: group, groupVM: groupVM, expenseToEdit: exp)
        }
        .sheet(isPresented: $showSettings) {
            GroupSettingsSheet(
                groupVM: groupVM,
                friendsVM: friendsVM,
                group: group,
                simplifyDebts: group.simplifyDebts,
                onUpdateSimplify: { newValue in updateSimplifyDebts(newValue) },
                onDeleteGroup: deleteGroup,
                onLeaveGroup: leaveGroup
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .accessibilityLabel("Group Settings")
                }
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        guard let idx = group.expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        let offsets = IndexSet(integer: idx)
        let expenseVM = ExpenseViewModel(groupVM: groupVM)
        expenseVM.deleteExpenses(at: offsets, from: group)
        expenseVM.groupVM.logActivity(for: group.id, text: "Deleted expense \(expense.title)")
        syncGroup()
    }

    private func updateSimplifyDebts(_ newValue: Bool) {
        if let idx = groupVM.groups.firstIndex(where: { $0.id == group.id }) {
            groupVM.groups[idx].simplifyDebts = newValue
            groupVM.logActivity(for: group.id, text: "Simplify group debts \(newValue ? "enabled" : "disabled")")
            syncGroup()
        }
    }

    private func deleteGroup() {
        groupVM.deleteGroup(group)
    }

    private func leaveGroup() {
        // Remove self from the group
        if let me = FriendsViewModel.shared.currentUser {
            groupVM.removeMember(me, from: group)
        }
    }
}

// --- Subviews ---

struct HeaderCard: View {
    let group: Group
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color(group.colorName).opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: group.iconName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(ChillTheme.darkText)
                }
                VStack(alignment: .leading) {
                    Text(group.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ChillTheme.darkText)
                    Text("\(group.members.count) members")
                        .font(.subheadline)
                        .foregroundColor(ChillTheme.darkText.opacity(0.7))
                }
                Spacer()
            }
        }
        .padding()
        .background(
            // Blend the group's colour softly into the card background for light mode
            LinearGradient(
                gradient: Gradient(colors: [Color(group.colorName).opacity(0.12), ChillTheme.card]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color(group.colorName).opacity(0.1), radius: 8, x: 0, y: 3)
    }
}

struct ExpensesSwipeCard: View {
    let group: Group
    let groupVM: GroupViewModel
    let onEdit: (Expense) -> Void
    let onDelete: (Expense) -> Void

    var body: some View {
        if !group.expenses.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Expenses")
                    .font(.title3.bold())
                    .foregroundColor(ChillTheme.darkText)
                ForEach(Array(group.expenses.sorted(by: { $0.date > $1.date })), id: \.id) { expense in
                    ExpenseRow(
                        expense: expense,
                        onEdit: { onEdit(expense) },
                        onDelete: { onDelete(expense) }
                    )
                }
            }
            .padding()
            .background(ChillTheme.card)
            .cornerRadius(22)
            .shadow(color: ChillTheme.lightShadow, radius: 7, x: 0, y: 2)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.18))
                    .frame(width: 38, height: 38)
                // --- UPDATED: Show both emoji AND category name ---
                HStack(spacing: 4) {
                    Text(expense.category.emoji)
                        .font(.system(size: 20))
                    Text(expense.category.displayName)
                        .font(.caption)
                        .foregroundColor(ChillTheme.darkText)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundColor(ChillTheme.darkText)
                HStack {
                    Text("\(expense.paidBy.name) paid \(expense.amount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(ChillTheme.darkText.opacity(0.7))
                    if expense.isRecurring {
                        Text("Recurring")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.18))
                            .cornerRadius(6)
                    }
                }
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(ChillTheme.accent)
            }
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(ChillTheme.card)
        .cornerRadius(12)
        .shadow(color: ChillTheme.lightShadow, radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
}

struct ActivityCard: View {
    let group: Group
    var body: some View {
        if !group.activity.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Activity")
                    .font(.title3.bold())
                    .foregroundColor(ChillTheme.darkText)
                ForEach(group.activity.sorted(by: { $0.date > $1.date }).prefix(5)) { activity in
                    Text(activity.text)
                        .font(.footnote)
                        .foregroundColor(ChillTheme.darkText.opacity(0.7))
                }
            }
            .padding()
            .background(ChillTheme.card)
            .cornerRadius(22)
            .shadow(color: ChillTheme.lightShadow, radius: 7, x: 0, y: 2)
        }
    }
}

// Avatar color helper
extension Color {
    static func avatarColor(for user: User) -> Color {
        let colors: [Color] = [.blue, .teal, .pink, .orange, .purple, .red, .yellow, .green]
        if let first = user.name.first {
            let idx = Int(first.asciiValue ?? 0) % colors.count
            return colors[idx]
        }
        return .gray
    }
}
extension User {
    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined().uppercased()
    }
}
