import Foundation
import SwiftData

@Model
final class MealLogEntry {
    var timestamp: Date = Date()
    var timeZoneIdentifier: String = TimeZone.current.identifier
    var utcOffsetSeconds: Int = TimeZone.current.secondsFromGMT()

    @Relationship
    var template: MealTemplate?
    var notes: String?
    
    // Inline meal flag (optional for migration safety)
    // When true, this indicates the template is a one-time inline meal
    // and should be hidden from the Meals tab
    var isInline: Bool = false

    init(
        timestamp: Date = Date(),
        timeZoneIdentifier: String = TimeZone.current.identifier,
        utcOffsetSeconds: Int? = nil,
        template: MealTemplate?,
        notes: String? = nil,
        isInline: Bool = false
    ) {
        self.timestamp = timestamp
        self.timeZoneIdentifier = timeZoneIdentifier

        let tz = TimeZone(identifier: timeZoneIdentifier) ?? .current
        self.utcOffsetSeconds = utcOffsetSeconds ?? tz.secondsFromGMT(for: timestamp)

        self.template = template
        self.notes = notes
        self.isInline = isInline
    }
}
