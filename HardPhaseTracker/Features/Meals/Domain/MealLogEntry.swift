import Foundation
import SwiftData

@Model
final class MealLogEntry {
    var timestamp: Date

    var template: MealTemplate?
    var notes: String?

    init(timestamp: Date = Date(), template: MealTemplate?, notes: String? = nil) {
        self.timestamp = timestamp
        self.template = template
        self.notes = notes
    }
}
