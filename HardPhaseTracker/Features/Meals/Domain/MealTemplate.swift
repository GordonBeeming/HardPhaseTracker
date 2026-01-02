import Foundation
import SwiftData

@Model
final class MealTemplate {
    var name: String
    var protein: Double
    var carbs: Double
    var fats: Double

    @Relationship(inverse: \MealComponent.template)
    var components: [MealComponent]

    init(
        name: String,
        protein: Double = 0,
        carbs: Double = 0,
        fats: Double = 0,
        components: [MealComponent] = []
    ) {
        self.name = name
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.components = components
    }
}
