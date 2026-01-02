import SwiftData
import Testing
@testable import HardPhaseTracker

struct MealTemplatePersistenceTests {
    @Test func canCreateAndFetchTemplates() async throws {
        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let template = MealTemplate(
            name: "Test Meal",
            protein: 10,
            carbs: 20,
            fats: 5,
            components: [MealComponent(name: "Chicken", grams: 200)]
        )
        context.insert(template)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealTemplate>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Test Meal")
        #expect(fetched.first?.components.count == 1)
    }
}
