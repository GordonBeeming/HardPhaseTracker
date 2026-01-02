import SwiftData

@Model
final class AppSettings {
    @Relationship
    var selectedSchedule: EatingWindowSchedule?

    // Dashboard
    var alwaysShowLogMealButton: Bool
    var logMealShowBeforeHours: Double
    var logMealShowAfterHours: Double
    var dashboardMealListCount: Int? // migration-safe

    // Meals / time display (optional for migration safety)
    var mealTimeDisplayMode: String? // "captured" | "device"
    var mealTimeZoneBadgeStyle: String? // "abbrev"
    var mealTimeOffsetStyle: String? // legacy (not shown in UI)

    // Global
    var unitSystem: String? // "metric" | "imperial"

    init(
        selectedSchedule: EatingWindowSchedule? = nil,
        alwaysShowLogMealButton: Bool = false,
        logMealShowBeforeHours: Double = 0.5,
        logMealShowAfterHours: Double = 2.5,
        dashboardMealListCount: Int = 10,
        mealTimeDisplayMode: String = "captured",
        mealTimeZoneBadgeStyle: String = "abbrev",
        mealTimeOffsetStyle: String = "utc",
        unitSystem: String = "metric"
    ) {
        self.selectedSchedule = selectedSchedule
        self.alwaysShowLogMealButton = alwaysShowLogMealButton
        self.logMealShowBeforeHours = logMealShowBeforeHours
        self.logMealShowAfterHours = logMealShowAfterHours
        self.dashboardMealListCount = dashboardMealListCount
        self.mealTimeDisplayMode = mealTimeDisplayMode
        self.mealTimeZoneBadgeStyle = mealTimeZoneBadgeStyle
        self.mealTimeOffsetStyle = mealTimeOffsetStyle
        self.unitSystem = unitSystem
    }
}
