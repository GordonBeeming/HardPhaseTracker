import Foundation
import SwiftData

enum MealTemplateKind: String {
    case meal
    case electrolyte
}

@Model
final class MealTemplate {
    var name: String = ""
    var protein: Double = 0
    var carbs: Double = 0
    var fats: Double = 0

    /// "meal" | "electrolyte" (optional for migration safety)
    var kind: String?

    @Relationship(inverse: \MealComponent.template)
    var components: [MealComponent]? = []

    @Relationship(inverse: \MealLogEntry.template)
    var mealLogEntries: [MealLogEntry]? = []

    @Relationship(inverse: \ElectrolyteIntakeEntry.template)
    var electrolyteIntakeEntries: [ElectrolyteIntakeEntry]? = []

    @Relationship(inverse: \AppSettings.electrolyteTemplates)
    var selectedInSettings: [AppSettings]? = []

    var componentsList: [MealComponent] {
        components ?? []
    }

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
