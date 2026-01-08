import Foundation
import SwiftData

@Model
final class AppSettings {
    @Relationship
    var selectedSchedule: EatingWindowSchedule?

    // Dashboard
    var alwaysShowLogMealButton: Bool = false
    var logMealShowBeforeHours: Double = 0.5
    var logMealShowAfterHours: Double = 2.5
    var dashboardMealListCount: Int? // migration-safe

    // Meals / time display (optional for migration safety)
    var mealTimeDisplayMode: String? // "captured" | "device"
    var mealTimeZoneBadgeStyle: String? // "abbrev"
    var mealTimeOffsetStyle: String? // legacy (not shown in UI)

    // Electrolytes
    @Relationship
    var electrolyteTemplates: [MealTemplate]? = []

    /// "fixed" | "askEachTime" (optional for migration safety)
    var electrolyteSelectionMode: String?

    // Global
    var unitSystem: String? // "metric" | "imperial"

    // Analysis (optional for migration safety)
    var weeklyProteinGoalGrams: Double? // 0 == off

    // Health monitoring (optional for migration safety)
    var weightGoalKg: Double? // nil == not set
    var healthMonitoringStartDate: Date? // nil == use first app launch date
    var healthDataMaxPullDays: Int? // nil == use default (90 days)

    init(
        selectedSchedule: EatingWindowSchedule? = nil,
        alwaysShowLogMealButton: Bool = false,
        logMealShowBeforeHours: Double = 0.5,
        logMealShowAfterHours: Double = 2.5,
        dashboardMealListCount: Int = 10,
        mealTimeDisplayMode: String = "captured",
        mealTimeZoneBadgeStyle: String = "abbrev",
        mealTimeOffsetStyle: String = "utc",
        electrolyteTemplates: [MealTemplate] = [],
        electrolyteSelectionMode: String = "fixed",
        unitSystem: String = "metric",
        weeklyProteinGoalGrams: Double = 0,
        weightGoalKg: Double? = nil,
        healthMonitoringStartDate: Date? = nil,
        healthDataMaxPullDays: Int? = nil
    ) {
        self.selectedSchedule = selectedSchedule
        self.alwaysShowLogMealButton = alwaysShowLogMealButton
        self.logMealShowBeforeHours = logMealShowBeforeHours
        self.logMealShowAfterHours = logMealShowAfterHours
        self.dashboardMealListCount = dashboardMealListCount
        self.mealTimeDisplayMode = mealTimeDisplayMode
        self.mealTimeZoneBadgeStyle = mealTimeZoneBadgeStyle
        self.mealTimeOffsetStyle = mealTimeOffsetStyle
        self.electrolyteTemplates = electrolyteTemplates
        self.electrolyteSelectionMode = electrolyteSelectionMode
        self.unitSystem = unitSystem
        self.weeklyProteinGoalGrams = weeklyProteinGoalGrams
        self.weightGoalKg = weightGoalKg
        self.healthMonitoringStartDate = healthMonitoringStartDate
        self.healthDataMaxPullDays = healthDataMaxPullDays
    }
}
