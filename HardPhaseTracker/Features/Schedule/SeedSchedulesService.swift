import Foundation
import SwiftData

enum SeedSchedulesService {
    private static let seedKey = "didSeedSchedules_v1"

    static func seedIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        let existing = (try? modelContext.fetch(FetchDescriptor<EatingWindowSchedule>())) ?? []

        // Ensure built-ins always exist (idempotent upsert by name).
        let existingNames = Set(existing.map { $0.name })
        for builtIn in ScheduleTemplates.defaults() where !existingNames.contains(builtIn.name) {
            modelContext.insert(builtIn)
        }

        // Backfill built-in flag for existing installs (best-effort by name).
        for s in existing where s.name.contains("16/8") || s.name.contains("18/6") || s.name.contains("20/4") || s.name.contains("OMAD") {
            s.isBuiltIn = true
        }

        let currentSettings = (try? modelContext.fetch(FetchDescriptor<AppSettings>()).first)

        if currentSettings == nil {
            // First launch: force user to pick a schedule (onboarding).
            modelContext.insert(AppSettings(selectedSchedule: nil))
        } else {
            // Backfill new settings fields for existing installs (migration-safe).
            if currentSettings?.mealTimeDisplayMode == nil { currentSettings?.mealTimeDisplayMode = "captured" }
            if currentSettings?.mealTimeZoneBadgeStyle == nil { currentSettings?.mealTimeZoneBadgeStyle = "abbrev" }
            if currentSettings?.mealTimeOffsetStyle == nil { currentSettings?.mealTimeOffsetStyle = "utc" }
            if currentSettings?.dashboardMealListCount == nil { currentSettings?.dashboardMealListCount = 10 }
            if currentSettings?.unitSystem == nil { currentSettings?.unitSystem = "metric" }
        }

        modelContext.saveLogged()
        UserDefaults.standard.set(true, forKey: seedKey)
    }
}
