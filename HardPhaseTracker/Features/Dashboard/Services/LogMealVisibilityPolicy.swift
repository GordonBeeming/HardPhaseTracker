import Foundation

enum LogMealVisibilityPolicy {
    static func shouldShowPrimary(
        alwaysShow: Bool,
        showBeforeHours: Double,
        showAfterHours: Double,
        schedule: EatingWindowSchedule?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard let schedule else { return false }
        if alwaysShow { return true }

        if EatingWindowNavigator.currentWindowRange(schedule: schedule, now: now, calendar: calendar) != nil {
            return true
        }

        let before = showBeforeHours * 3600
        let after = showAfterHours * 3600

        if let nextStart = EatingWindowNavigator.nextWindowStart(schedule: schedule, now: now, calendar: calendar) {
            if nextStart.timeIntervalSince(now) <= before { return true }
        }

        if let prevEnd = EatingWindowNavigator.previousWindowEnd(schedule: schedule, now: now, calendar: calendar) {
            if now.timeIntervalSince(prevEnd) <= after { return true }
        }

        return false
    }
}
