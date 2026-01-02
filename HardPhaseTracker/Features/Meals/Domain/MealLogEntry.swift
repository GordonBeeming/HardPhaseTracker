import Foundation
import SwiftData

@Model
final class MealLogEntry {
    var timestamp: Date
    var timeZoneIdentifier: String
    var utcOffsetSeconds: Int

    var template: MealTemplate?
    var notes: String?

    init(
        timestamp: Date = Date(),
        timeZoneIdentifier: String = TimeZone.current.identifier,
        utcOffsetSeconds: Int = TimeZone.current.secondsFromGMT(for: timestamp),
        template: MealTemplate?,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.timeZoneIdentifier = timeZoneIdentifier
        self.utcOffsetSeconds = utcOffsetSeconds
        self.template = template
        self.notes = notes
    }
}
