import Foundation
import UniformTypeIdentifiers

class ExportManager {
    static func generateCSV(for expenses: [Expense]) -> String {
        var csv = "Date,Description,Category,Amount,Paid By,Participants\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        for e in expenses {
            let dateString = formatter.string(from: e.date)
            let participants = e.participants.map { $0.name }.joined(separator: ";")
            // Fix: Use e.title (not e.description)
            csv += "\"\(dateString)\",\"\(e.title)\",\"\(e.category.displayName)\",\"\(e.amount)\",\"\(e.paidBy.name)\",\"\(participants)\"\n"
        }
        return csv
    }
}
