import Foundation
import Testing
@testable import HardPhaseTracker

struct LogMealVisibilityPolicyTests {
    @Test func showsWhenWithinBeforeWindow() async throws {
        let allDays = EatingWindowSchedule.mask(for: [1,2,3,4,5,6,7])
        let schedule = EatingWindowSchedule(name: "16/8", startMinutes: 12*60, endMinutes: 20*60, weekdayMask: allDays, isBuiltIn: true)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Monday 10:00 (2h before 12:00 start)
        let now = Date(timeIntervalSince1970: 1767571200 + 10*3600)

        #expect(LogMealVisibilityPolicy.shouldShowPrimary(alwaysShow: false, showBeforeHours: 2.5, showAfterHours: 2.5, schedule: schedule, now: now, calendar: calendar) == true)
    }

    @Test func hidesWhenFarOutsideWindows() async throws {
        let allDays = EatingWindowSchedule.mask(for: [1,2,3,4,5,6,7])
        let schedule = EatingWindowSchedule(name: "16/8", startMinutes: 12*60, endMinutes: 20*60, weekdayMask: allDays, isBuiltIn: true)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Monday 03:00 (9h before start) -> should hide with before=2.5
        let now = Date(timeIntervalSince1970: 1767571200 + 3*3600)

        #expect(LogMealVisibilityPolicy.shouldShowPrimary(alwaysShow: false, showBeforeHours: 2.5, showAfterHours: 2.5, schedule: schedule, now: now, calendar: calendar) == false)
    }
}
