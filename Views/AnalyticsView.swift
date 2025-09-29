import SwiftUI
import Charts

/// Provides a visual summary of spending within a group. Displays
/// category totals, member totals and general statistics.
struct AnalyticsView: View {
    var group: Group
    var groupVM: GroupViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    private var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        var dict: [ExpenseCategory: Double] = [:]
        for expense in group.expenses {
            dict[expense.category, default: 0] += expense.amount
        }
        return dict.map { ($0.key, $0.value) }.sorted(by: { $0.total > $1.total })
    }
    
    private var memberTotals: [(user: User, total: Double)] {
        var dict: [User: Double] = [:]
        for expense in group.expenses {
            dict[expense.paidBy, default: 0] += expense.amount
        }
        return dict.map { ($0.key, $0.value) }.sorted(by: { $0.total > $1.total })
    }
    
    private var totalSpent: Double {
        group.expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var averagePerMember: Double {
        guard !group.members.isEmpty else { return 0 }
        return totalSpent / Double(group.members.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(label: Text("Summary").font(.headline)) {
                        VStack(alignment: .leading, spacing: 4) {
                            let totalSpentString = String(format: "%.2f", totalSpent)
                            let averagePerMemberString = String(format: "%.2f", averagePerMember)
                            Text("Total spent: \(group.currency.symbol)\(totalSpentString)")
                            Text("Number of expenses: \(group.expenses.count)")
                            Text("Average per member: \(group.currency.symbol)\(averagePerMemberString)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Category chart
                    if !categoryTotals.isEmpty {
                        GroupBox(label: Text("By Category").font(.headline)) {
                            Chart(categoryTotals, id: \.category) { item in
                                BarMark(
                                    x: .value("Category", item.category.displayName),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(Color.blue)
                            }
                            .frame(height: 200)
                            .chartYAxisLabel("Amount")
                            .chartXAxisLabel("Category")
                        }
                    }
                    
                    // Member chart
                    if !memberTotals.isEmpty {
                        GroupBox(label: Text("By Payer").font(.headline)) {
                            Chart(memberTotals, id: \.user) { item in
                                BarMark(
                                    x: .value("Member", item.user.name),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(Color.green)
                            }
                            .frame(height: 200)
                            .chartYAxisLabel("Amount")
                            .chartXAxisLabel("Member")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}
