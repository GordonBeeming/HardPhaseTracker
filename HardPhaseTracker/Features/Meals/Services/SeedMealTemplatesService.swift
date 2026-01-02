import Foundation
import SwiftData

enum SeedMealTemplatesService {
    private static let seedKey = "didSeedMealTemplates_v1"

    static func seedIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        let count = (try? modelContext.fetchCount(FetchDescriptor<MealTemplate>())) ?? 0
        guard count == 0 else {
            UserDefaults.standard.set(true, forKey: seedKey)
            return
        }

        StarterMeals.templates().forEach { modelContext.insert($0) }
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: seedKey)
    }
}
