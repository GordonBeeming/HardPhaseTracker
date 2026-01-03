import Foundation
import SwiftData

@Model
final class ElectrolyteIntakeEntry {
    var timestamp: Date
    /// Cached start-of-day for efficient filtering.
    var dayStart: Date
    var slotIndex: Int

    @Relationship
    var template: MealTemplate?

    init(timestamp: Date = Date(), slotIndex: Int, template: MealTemplate? = nil) {
        self.timestamp = timestamp
        self.dayStart = Calendar.current.startOfDay(for: timestamp)
        self.slotIndex = slotIndex
        self.template = template
    }
}
