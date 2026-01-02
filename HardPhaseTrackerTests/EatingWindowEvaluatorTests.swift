import Foundation
import Testing
@testable import HardPhaseTracker

struct EatingWindowEvaluatorTests {
    @Test func detectsInWindowForActiveDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let weekdays = EatingWindowSchedule.mask(for: [2]) // Monday
        let schedule = EatingWindowSchedule(name: "Test", startMinutes: 12*60, endMinutes: 20*60, weekdayMask: weekdays)

        // 2026-01-05 is a Monday
        let date = Date(timeIntervalSince1970: 1767571200 + 13*3600) // 13:00 UTC
        #expect(EatingWindowEvaluator.isNowInWindow(schedule: schedule, now: date, calendar: calendar) == true)
    }
}
