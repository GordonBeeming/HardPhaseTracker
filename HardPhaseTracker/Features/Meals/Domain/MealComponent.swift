import Foundation
import SwiftData

@Model
final class MealComponent {
    var name: String
    var grams: Double

    var template: MealTemplate?

    init(name: String, grams: Double) {
        self.name = name
        self.grams = grams
    }
}
