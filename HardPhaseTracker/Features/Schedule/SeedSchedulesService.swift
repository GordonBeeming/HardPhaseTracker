import Foundation
import SwiftData

enum SeedSchedulesService {
    private static let firstLaunchDateKey = "app.firstLaunchDate"

    static func seedIfNeeded(modelContext: ModelContext) {
        // Always ensure system schedules exist (every app launch).
        ensureSystemSchedulesExist(modelContext: modelContext)

        let currentSettings = (try? modelContext.fetch(FetchDescriptor<AppSettings>()).first)

        if currentSettings == nil {
            // First launch: create settings and record first launch date.
            let firstLaunchDate = Date()
            UserDefaults.standard.set(firstLaunchDate, forKey: firstLaunchDateKey)

            let settings = AppSettings()
            settings.healthMonitoringStartDate = firstLaunchDate
            settings.healthDataMaxPullDays = 90
            modelContext.insert(settings)
        } else {
            // Backfill new settings fields for existing installs (migration-safe).
            if currentSettings?.mealTimeDisplayMode == nil { currentSettings?.mealTimeDisplayMode = "captured" }
            if currentSettings?.mealTimeZoneBadgeStyle == nil { currentSettings?.mealTimeZoneBadgeStyle = "abbrev" }
            if currentSettings?.mealTimeOffsetStyle == nil { currentSettings?.mealTimeOffsetStyle = "utc" }
            if currentSettings?.dashboardMealListCount == nil { currentSettings?.dashboardMealListCount = 10 }
            if currentSettings?.unitSystem == nil { currentSettings?.unitSystem = "metric" }

            // Backfill health monitoring settings for existing installs.
            if currentSettings?.healthMonitoringStartDate == nil {
                // Use stored first launch date, or fallback to today if not recorded.
                let firstLaunch = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date ?? Date()
                currentSettings?.healthMonitoringStartDate = firstLaunch
                UserDefaults.standard.set(firstLaunch, forKey: firstLaunchDateKey)
            }
            if currentSettings?.healthDataMaxPullDays == nil {
                currentSettings?.healthDataMaxPullDays = 90
            }
        }

        modelContext.saveLogged()
    }

    private static func ensureSystemSchedulesExist(modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<EatingWindowSchedule>())) ?? []
        let existingNames = Set(existing.map { $0.name })

        // Always insert missing system schedules.
        for builtIn in ScheduleTemplates.defaults() where !existingNames.contains(builtIn.name) {
            modelContext.insert(builtIn)
        }

        // Mark existing schedules as built-in if they match system names (best-effort by name).
        for s in existing where !s.isBuiltIn {
            if s.name.contains("16/8") || s.name.contains("18/6") || s.name.contains("20/4") || s.name.contains("OMAD") {
                s.isBuiltIn = true
            }
        }
    }
}
