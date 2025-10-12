import Foundation

struct Group: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var members: [User]
    var expenses: [Expense]
    var isPublic: Bool
    var budget: Double?
    var activity: [Activity]
    var currency: Currency
    var colorName: String
    var iconName: String
    var adjustments: [Adjustment]
    var simplifyDebts: Bool

    // MARK: - Default Initializer
    init(
        id: String = UUID().uuidString,
        name: String,
        members: [User],
        expenses: [Expense] = [],
        isPublic: Bool = false,
        budget: Double? = nil,
        activity: [Activity] = [],
        currency: Currency = .usd,
        colorName: String = "blue",
        iconName: String = "person.3.fill",
        adjustments: [Adjustment] = [],
        simplifyDebts: Bool = false
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.expenses = expenses
        self.isPublic = isPublic
        self.budget = budget
        self.activity = activity
        self.currency = currency
        self.colorName = colorName
        self.iconName = iconName
        self.adjustments = adjustments
        self.simplifyDebts = simplifyDebts
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, members, expenses, isPublic, budget, activity, currency, colorName, iconName, adjustments, simplifyDebts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid.uuidString
        } else {
            id = UUID().uuidString
        }
        name = try container.decode(String.self, forKey: .name)
        members = try container.decode([User].self, forKey: .members)
        expenses = try container.decode([Expense].self, forKey: .expenses)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        budget = try container.decodeIfPresent(Double.self, forKey: .budget)
        activity = try container.decodeIfPresent([Activity].self, forKey: .activity) ?? []
        currency = try container.decodeIfPresent(Currency.self, forKey: .currency) ?? .usd
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName) ?? "blue"
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "person.3.fill"
        adjustments = try container.decodeIfPresent([Adjustment].self, forKey: .adjustments) ?? []
        simplifyDebts = try container.decodeIfPresent(Bool.self, forKey: .simplifyDebts) ?? false
    }
}
