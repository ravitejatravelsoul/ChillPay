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

    // Serialize group to a dictionary for Firestore.  This representation includes
    // full member dictionaries and a separate array of member IDs for efficient
    // Firestore queries.  Expenses, activity logs and adjustments are
    // serialized via their own `toDict` helpers.
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "members": members.map { $0.toDict() },
            // Also store member IDs separately for efficient Firestore queries
            "memberIds": members.map { $0.id },
            "expenses": expenses.map { $0.toDict() },
            "isPublic": isPublic,
            "budget": budget as Any,
            "activity": activity.map { $0.toDict() },
            "currency": currency.rawValue,
            "colorName": colorName,
            "iconName": iconName,
            "adjustments": adjustments.map { $0.toDict() },
            "simplifyDebts": simplifyDebts
        ]
    }

    /// Initialize a Group from a dictionary pulled from Firestore.  This
    /// initializer attempts to decode all nested collections (members,
    /// expenses, activity, adjustments) back into their respective model
    /// objects.  If mandatory fields are missing, it returns `nil`.
    static func fromDict(_ dict: [String: Any]) -> Group? {
        // Be resilient to missing fields in older docs or docs where we purposely
        // don't embed large arrays (expenses live in a subcollection).
        guard
            let id = dict["id"] as? String,
            let name = dict["name"] as? String,
            let membersArr = dict["members"] as? [[String: Any]]
        else { return nil }

        let expensesArr = dict["expenses"] as? [[String: Any]] ?? []
        let isPublic = dict["isPublic"] as? Bool ?? false

        let currencyRaw = dict["currency"] as? String
        let currency = currencyRaw.flatMap { Currency(rawValue: $0) } ?? .usd

        let colorName = dict["colorName"] as? String ?? "blue"
        let iconName = dict["iconName"] as? String ?? "person.3.fill"
        let adjustmentsArr = dict["adjustments"] as? [[String: Any]] ?? []
        let simplifyDebts = dict["simplifyDebts"] as? Bool ?? false

        let budget = dict["budget"] as? Double
        let activityArr = dict["activity"] as? [[String: Any]] ?? []

        // Convert nested dictionaries back to model objects
        let members: [User] = membersArr.compactMap { User.fromDict($0) }
        let expenses: [Expense] = expensesArr.compactMap { Expense.fromDict($0) }
        let activity: [Activity] = activityArr.compactMap { Activity.fromDict($0) }
        let adjustments: [Adjustment] = adjustmentsArr.compactMap { Adjustment.fromDict($0) }
        return Group(
            id: id,
            name: name,
            members: members,
            expenses: expenses,
            isPublic: isPublic,
            budget: budget,
            activity: activity,
            currency: currency,
            colorName: colorName,
            iconName: iconName,
            adjustments: adjustments,
            simplifyDebts: simplifyDebts
        )
    }

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
