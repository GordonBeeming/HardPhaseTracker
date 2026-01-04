import Foundation
import SwiftData

@Model
final class ElectrolyteIntakeEntry {
    var timestamp: Date = Date()
    /// Cached start-of-day for efficient filtering.
    var dayStart: Date = Calendar.current.startOfDay(for: Date())
    var slotIndex: Int = 0

    @Relationship
    var template: MealTemplate?

    init(timestamp: Date = Date(), slotIndex: Int, template: MealTemplate? = nil) {
        self.timestamp = timestamp
        self.dayStart = Calendar.current.startOfDay(for: timestamp)
        self.slotIndex = slotIndex
        self.template = template
    }
}
