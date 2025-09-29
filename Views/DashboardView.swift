import SwiftUI

struct DashboardView: View {
    // Demo data
    let totalBalance: Int = 12300
    let youOwe: Int = 2500
    let youAreOwed: Int = 39000
    let activities: [ActivityItem] = [
        .init(icon: "cup.and.saucer.fill", label: "Coffee with Sara", amount: -350),
        .init(icon: "fork.knife", label: "Dinner at Pind Balluchi", amount: 1200),
        .init(icon: "house.fill", label: "Rent - July", amount: -25000),
        .init(icon: "cart.fill", label: "Groceries", amount: 800)
    ]
    
    var body: some View {
        ZStack {
            ChillTheme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dashboard")
                        .font(ChillTheme.headerFont)
                        .foregroundColor(ChillTheme.darkText)
                    
                    // Balance gradient card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Balance")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.headline)
                        Text("₹\(Self.indianCurrencyString(totalBalance))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChillTheme.dashboardGradient)
                    .cornerRadius(ChillTheme.cardRadius)
                    
                    // Owe Chips
                    HStack(spacing: 20) {
                        DashboardChip(label: "You Owe", value: "₹\(Self.indianCurrencyString(youOwe))", color: ChillTheme.chipOwe)
                        DashboardChip(label: "You Are Owed", value: "₹\(Self.indianCurrencyString(youAreOwed))", color: ChillTheme.chipOwed)
                    }
                }
                .padding(.horizontal)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(ChillTheme.darkText)
                        Spacer()
                        Button(action: {}) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    ForEach(activities) { item in
                        ActivityRow(item: item)
                    }
                }
                .padding()
                .background(ChillTheme.card)
                .cornerRadius(ChillTheme.cardRadius)
                .padding(.horizontal)
                .padding(.bottom, 72)
                
                Spacer()
            }
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Add Expense action
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 8)
                    .padding(.trailing, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            VStack {
                Spacer()
                CustomTabBar()
            }
        )
    }
    
    // MARK: - Helper for Indian currency formatting
    static func indianCurrencyString(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Components

struct DashboardChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(ChillTheme.captionFont)
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
        }
        .frame(width: 120, height: 54)
        .background(color)
        .cornerRadius(ChillTheme.chipRadius)
        .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(ChillTheme.accent.opacity(0.14))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(ChillTheme.accent)
                )
            Text(item.label)
                .foregroundColor(ChillTheme.darkText)
            Spacer()
            Text(item.amount < 0 ? "- ₹\(DashboardView.indianCurrencyString(abs(item.amount)))" : "+ ₹\(DashboardView.indianCurrencyString(item.amount))")
                .font(.headline)
                .foregroundColor(item.amount < 0 ? ChillTheme.chipOwe : ChillTheme.accent)
        }
        .padding(.vertical, 6)
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let amount: Int
}

struct CustomTabBar: View {
    var body: some View {
        HStack {
            Spacer()
            TabBarButton(icon: "house.fill", isSelected: true)
            Spacer()
            TabBarButton(icon: "person.2.fill", isSelected: false)
            Spacer()
            TabBarButton(icon: "message.fill", isSelected: false)
            Spacer()
            TabBarButton(icon: "gearshape.fill", isSelected: false)
            Spacer()
        }
        .padding(.vertical, 10)
        .background(ChillTheme.tabBar)
        .cornerRadius(24)
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.13), radius: 6, x: 0, y: 2)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 26, weight: .medium))
            .foregroundColor(isSelected ? ChillTheme.accent : ChillTheme.softGray)
            .frame(width: 40, height: 40)
            .background(isSelected ? ChillTheme.accent.opacity(0.13) : Color.clear)
            .cornerRadius(14)
    }
}
