import Foundation

enum StarterMeals {
    static func templates() -> [MealTemplate] {
        // Keep starter templates generic (no personal meal plans).
        return [MealTemplate(name: "Meal")]
    }
}
