import SwiftUI
import AVFoundation

struct FriendDetailView: View {
    let friend: User
    let friendsVM: FriendsViewModel
    let groupVM: GroupViewModel
    let allExpenses: [Expense]
    let balance: Double

    @State private var showAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var showDeleteAlert = false
    @State private var showSettleConfirmation = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @Environment(\.presentationMode) private var presentationMode

    /// Access the currency manager for formatting balances and expenses.
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var isSettled: Bool {
        abs(balance) < 0.01
    }

    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Card
                    HStack(spacing: 18) {
                        AvatarView(user: friend)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 6) {
                            // Friend name uses dark text colour on light card
                            Text(friend.name)
                                .font(.title2).bold()
                                .foregroundColor(ChillTheme.darkText)
                            if let email = friend.email {
                                Text(email)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(24)

                    // Balance Card: Always show amount
                    let epsilon = 0.01
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Balance with \(friend.name):")
                            .foregroundColor(.secondary)
                        if balance < -epsilon {
                            Text("You owe \(currencyManager.format(amount: abs(balance)))")
                                .foregroundColor(.red)
                                .font(.title.bold())
                        } else if balance > epsilon {
                            Text("\(friend.name) owes you \(currencyManager.format(amount: abs(balance)))")
                                .foregroundColor(.green)
                                .font(.title.bold())
                        } else {
                            Text("Settled")
                                .foregroundColor(.secondary)
                                .font(.title.bold())
                        }
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(24)

                    // Actions
                    HStack(spacing: 16) {
                        // Use primary button style for Add Expense
                        ChillPrimaryButton(title: "Add Expense", isDisabled: false) {
                            showAddExpense = true
                        }
                        // Custom settle up button only shown if balance is not zero
                        if abs(balance) > epsilon {
                            Button(action: {
                                showSettleConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.arrow.left.circle")
                                    Text("Settle Up")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(ChillTheme.card)
                                .foregroundColor(ChillTheme.darkText)
                                .cornerRadius(16)
                            }
                        }
                    }

                    // Transaction History
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Expenses with \(friend.name)")
                            .font(.title3).bold()
                            .foregroundColor(ChillTheme.darkText)

                        if allExpenses.isEmpty {
                            Text("No expenses yet.")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(allExpenses) { expense in
                                FriendExpenseRow(
                                    expense: expense,
                                    currentUser: friendsVM.currentUser ?? User(id: UUID().uuidString, name: "Unknown", email: nil),
                                    onEdit: { selectedExpense = expense }
                                )
                                Divider().background(Color(.systemGray4))
                            }
                        }
                    }
                    .padding()
                    .background(ChillTheme.card)
                    .cornerRadius(24)

                    // --- Delete from Friends List Button ---
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete from friends list")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isSettled ? Color.red : Color.gray.opacity(0.7))
                        .cornerRadius(16)
                    }
                    .disabled(!isSettled)
                    .opacity(isSettled ? 1 : 0.5)
                    .padding(.top, 12)
                }
                .padding()
            }
            .navigationTitle(friend.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddDirectExpenseView(
                    friend: friend,
                    friendsVM: friendsVM,
                    expenseToEdit: nil // Add mode
                )
            }
            .sheet(item: $selectedExpense) { expense in
                AddDirectExpenseView(
                    friend: friend,
                    friendsVM: friendsVM,
                    expenseToEdit: expense // Edit mode
                )
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Remove Friend"),
                    message: Text("Are you sure you want to remove \(friend.name) from your friends list?"),
                    primaryButton: .destructive(Text("Remove")) {
                        friendsVM.removeFriend(friend)
                        selectedExpense = nil
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            // Settle Up confirmation alert
            .alert(isPresented: $showSettleConfirmation) {
                Alert(
                    title: Text("Settle Up"),
                    message: Text("Are you sure you want to settle up all expenses with \(friend.name)?"),
                    primaryButton: .destructive(Text("Settle")) {
                        friendsVM.settleUpWith(friend: friend)
                        celebrationMessage = "You are settled up with \(friend.name)!"
                        showCelebration = true
                    },
                    secondaryButton: .cancel()
                )
            }
            // Celebration Popup after settle up
            CelebrationPopup(show: $showCelebration, message: celebrationMessage)
        }
    }
}

// MARK: - FriendExpenseRow

struct FriendExpenseRow: View {
    let expense: Expense
    let currentUser: User
    var onEdit: (() -> Void)? = nil

    var isDirect: Bool { expense.groupID == nil }
    var canEdit: Bool { expense.paidBy.id == currentUser.id }
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(isDirect ? Color.green : Color.blue)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(isDirect ? "D" : "G")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundColor(.white)
                // Format amount using the user's currency to ensure consistency
                Text("Amount: \(currencyManager.format(amount: expense.amount))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Paid by \(expense.paidBy.name)\(isDirect ? "" : " (group)")")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            if canEdit, let onEdit = onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}
