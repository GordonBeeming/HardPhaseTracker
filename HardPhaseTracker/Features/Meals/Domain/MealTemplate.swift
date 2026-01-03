import Foundation
import SwiftData

enum MealTemplateKind: String {
    case meal
    case electrolyte
}

@Model
final class MealTemplate {
    var name: String
    var protein: Double
    var carbs: Double
    var fats: Double

    /// "meal" | "electrolyte" (optional for migration safety)
    var kind: String?

    @Relationship(inverse: \MealComponent.template)
    var components: [MealComponent]

    init(
        name: String,
        protein: Double = 0,
        carbs: Double = 0,
        fats: Double = 0,
        kind: String? = MealTemplateKind.meal.rawValue,
        components: [MealComponent] = []
    ) {
        self.name = name
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.kind = kind
        self.components = components
    }
}
