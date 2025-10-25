import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var paidBy: User
    var participants: [User]
    var date: Date
    var groupID: UUID? // nil if direct friend expense
    var comments: [Comment] = []
    var category: ExpenseCategory = .other
    var isRecurring: Bool = false

    // Firestore serialization
    func toDict() -> [String: Any] {
        [
            "id": id.uuidString,
            "title": title,
            "amount": amount,
            "paidBy": paidBy.toDict(),
            "participants": participants.map { $0.toDict() },
            "date": date.timeIntervalSince1970,
            "groupID": groupID?.uuidString as Any,
            "category": category.rawValue,
            "isRecurring": isRecurring
        ]
    }

    static func fromDict(_ dict: [String: Any]) -> Expense? {
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let title = dict["title"] as? String,
              let amount = dict["amount"] as? Double,
              let paidByDict = dict["paidBy"] as? [String: Any],
              let paidBy = User.fromDict(paidByDict),
              let participantsArr = dict["participants"] as? [[String: Any]],
              let dateTimestamp = dict["date"] as? Double,
              let categoryRaw = dict["category"] as? String,
              let category = ExpenseCategory(rawValue: categoryRaw),
              let isRecurring = dict["isRecurring"] as? Bool
        else { return nil }
        let participants = participantsArr.compactMap { User.fromDict($0) }
        let groupIDString = dict["groupID"] as? String
        let groupID = groupIDString != nil ? UUID(uuidString: groupIDString!) : nil
        return Expense(
            id: id,
            title: title,
            amount: amount,
            paidBy: paidBy,
            participants: participants,
            date: Date(timeIntervalSince1970: dateTimestamp),
            groupID: groupID,
            comments: [],
            category: category,
            isRecurring: isRecurring
        )
    }
}
