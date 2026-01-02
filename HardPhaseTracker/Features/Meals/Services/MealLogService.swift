import Foundation
import SwiftData

enum MealLogService {
    static func logMeal(
        template: MealTemplate,
        at timestamp: Date,
        notes: String? = nil,
        in timeZone: TimeZone = .current,
        modelContext: ModelContext
    ) {
        let entry = MealLogEntry(
            timestamp: timestamp,
            timeZoneIdentifier: timeZone.identifier,
            utcOffsetSeconds: timeZone.secondsFromGMT(for: timestamp),
            template: template,
            notes: notes
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
