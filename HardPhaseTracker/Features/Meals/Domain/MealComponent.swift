import Foundation
import SwiftData

@Model
final class MealComponent {
    var name: String

    // Canonical stored value for now.
    var grams: Double

    // Migration-safe (optional) — used for display and input conversion.
    var unit: String?

    @Relationship
    var template: MealTemplate?

    init(name: String, grams: Double, unit: String = "g") {
        self.name = name
        self.grams = grams
        self.unit = unit
    }
}
