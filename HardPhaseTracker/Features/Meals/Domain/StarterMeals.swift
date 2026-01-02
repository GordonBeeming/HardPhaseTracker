import Foundation

enum StarterMeals {
    static func templates() -> [MealTemplate] {
        let thursdayLunch = MealTemplate(
            name: "Thursday Lunch",
            components: [
                MealComponent(name: "Eggs", grams: 0),
                MealComponent(name: "Sweet Potato", grams: 300),
                MealComponent(name: "Cheese", grams: 30),
                MealComponent(name: "Cucumber", grams: 175),
                MealComponent(name: "Tomato", grams: 125),
                MealComponent(name: "Spinach", grams: 30)
            ]
        )

        let sundayDinner = MealTemplate(
            name: "Sunday Dinner",
            components: [
                MealComponent(name: "Eggs", grams: 0),
                MealComponent(name: "White Potato", grams: 450),
                MealComponent(name: "Cheese", grams: 50),
                MealComponent(name: "Cucumber", grams: 350),
                MealComponent(name: "Tomato", grams: 250),
                MealComponent(name: "Spinach", grams: 60)
            ]
        )

        return [thursdayLunch, sundayDinner]
    }
}
