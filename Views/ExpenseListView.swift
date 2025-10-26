import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var groupVM: GroupViewModel
    @EnvironmentObject var friendsVM: FriendsViewModel
    @State var group: Group

    @State private var showAddExpense = false
    @State private var editingExpense: Expense?
    @State private var selectedExpense: Expense?
    @State private var showAnalytics = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                // MARK: - Expense List Section
                Section {
                    ForEach(group.expenses) { expense in
                        HStack(alignment: .top, spacing: 8) {
                            AvatarView(user: expense.paidBy)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.title)
                                    .font(.headline)

                                let amountString = String(format: "%.2f", expense.amount)
                                Text("Amount: \(group.currency.symbol)\(amountString)")

                                Text("Category: \(expense.category.displayName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("Paid by: \(expense.paidBy.name)")

                                let participantsString = expense.participants
                                    .map { $0.name }
                                    .joined(separator: ", ")
                                Text("Participants: \(participantsString)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                if expense.isRecurring {
                                    Text("Recurring")
                                        .font(.footnote)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedExpense = expense
                        }
                        .contextMenu {
                            Button(action: { editingExpense = expense }) {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                    }
                    .onDelete { offsets in
                        let expenseVM = ExpenseViewModel(groupVM: groupVM)
                        expenseVM.deleteExpenses(at: offsets, from: group)
                    }
                }

                // MARK: - Group Summary Section
                Section {
                    GroupSummarySection(
                        groupVM: groupVM,
                        group: group
                    )
                    .listRowInsets(EdgeInsets())
                    .background(Color(.systemBackground))
                }
            }
            .listStyle(.plain)
            .onAppear { syncGroup() }
            .onReceive(groupVM.$groups) { _ in syncGroup() }
            .navigationTitle(group.name)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense.toggle() }) {
                        Image(systemName: "plus")
                    }
                    Button(action: { showAnalytics = true }) {
                        Image(systemName: "chart.bar")
                    }
                }
            }

            // MARK: - Sheets
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(group: group, groupVM: groupVM)
                    .environmentObject(friendsVM)
            }

            .sheet(item: $editingExpense) { exp in
                AddExpenseView(group: group, groupVM: groupVM, expenseToEdit: exp)
                    .environmentObject(friendsVM)
            }

            .sheet(item: $selectedExpense) { exp in
                ExpenseDetailView(groupVM: groupVM, group: group, expense: exp)
                    .environmentObject(friendsVM)
            }

            .sheet(isPresented: $showAnalytics) {
                AnalyticsView(group: group)
                    .environmentObject(groupVM)
                    .environmentObject(friendsVM)
            }
        }
    }

    // MARK: - Helpers
    private func syncGroup() {
        if let updated = groupVM.groups.first(where: { $0.id == group.id }) {
            group = updated
        }
    }
}
