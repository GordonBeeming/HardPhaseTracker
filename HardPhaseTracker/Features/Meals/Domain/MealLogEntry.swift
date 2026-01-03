import Foundation
import SwiftData

@Model
final class MealLogEntry {
    var timestamp: Date = Date()
    var timeZoneIdentifier: String = TimeZone.current.identifier
    var utcOffsetSeconds: Int = TimeZone.current.secondsFromGMT()

    @Relationship(inverse: \MealTemplate.mealLogEntries)
    var template: MealTemplate?
    var notes: String?

    init(
        timestamp: Date = Date(),
        timeZoneIdentifier: String = TimeZone.current.identifier,
        utcOffsetSeconds: Int? = nil,
        template: MealTemplate?,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.timeZoneIdentifier = timeZoneIdentifier

        let tz = TimeZone(identifier: timeZoneIdentifier) ?? .current
        self.utcOffsetSeconds = utcOffsetSeconds ?? tz.secondsFromGMT(for: timestamp)

        self.template = template
        self.notes = notes
    }
}
