import Foundation
import Testing
@testable import HardPhaseTracker

struct WeeklyProteinAggregationServiceTests {
    @Test func aggregatesByISOWeek() async throws {
        let cal = Calendar(identifier: .iso8601)
        let now = cal.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 12, minute: 0))!
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: now)!
        let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start)!

        let meal = MealTemplate(name: "Meal", protein: 50)

        let e1 = MealLogEntry(timestamp: cal.date(byAdding: .day, value: 1, to: thisWeek.start)!, template: meal)
        let e2 = MealLogEntry(timestamp: cal.date(byAdding: .day, value: 2, to: thisWeek.start)!, template: meal)
        let e3 = MealLogEntry(timestamp: cal.date(byAdding: .day, value: 1, to: lastWeekStart)!, template: meal)

        let summaries = WeeklyProteinAggregationService.summaries(entries: [e1, e2, e3], goalGrams: 200, now: now, weeks: 2, calendar: cal)

        #expect(summaries.count == 2)
        #expect(summaries[0].weekStart == thisWeek.start)
        #expect(summaries[0].totalProteinGrams == 100)
        #expect(summaries[0].goalProteinGrams == 200)

        #expect(summaries[1].weekStart == lastWeekStart)
        #expect(summaries[1].totalProteinGrams == 50)
    }
}
