#if canImport(HealthKit)
import Foundation
import HealthKit
import Testing
@testable import HardPhaseTracker

struct HealthKitQuerySupportTests {
    @Test
    func startDateForLast7DaysIsStartOfDaySixDaysAgo() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = Date(timeIntervalSince1970: 1_700_000_000) // stable
        let start = HealthKitQuerySupport.startDateForLastDays(7, now: now, calendar: cal)

        let startOfToday = cal.startOfDay(for: now)
        let expected = cal.date(byAdding: .day, value: -6, to: startOfToday)!
        #expect(start == expected)
    }

    @Test
    func mapBodyFatConvertsFractionToPercent() {
        let type = HKQuantityType(.bodyFatPercentage)
        let quantity = HKQuantity(unit: .percent(), doubleValue: 0.21) // 21%
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let sample = HKQuantitySample(type: type, quantity: quantity, start: now, end: now)
        let mapped = HealthKitQuerySupport.mapBodyFat(sample)

        #expect(mapped.percent == 21.0)
    }

    @Test
    func aggregateSleepNightsSumsAsleepSamplesByEndDateDay() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let type = HKCategoryType(.sleepAnalysis)

        // Two asleep segments ending on the same day.
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let start1 = day.addingTimeInterval(-8 * 3600)
        let end1 = day.addingTimeInterval(-6 * 3600)
        let start2 = day.addingTimeInterval(-5 * 3600)
        let end2 = day.addingTimeInterval(-4 * 3600)

        let s1 = HKCategorySample(type: type, value: HKCategoryValueSleepAnalysis.asleepCore.rawValue, start: start1, end: end1)
        let s2 = HKCategorySample(type: type, value: HKCategoryValueSleepAnalysis.asleepREM.rawValue, start: start2, end: end2)

        let nights = HealthKitQuerySupport.aggregateSleepNights(samples: [s1, s2], nights: 7, calendar: cal)
        #expect(nights.count == 1)
        #expect(nights[0].asleepSeconds == (2 * 3600 + 1 * 3600))
    }
}
#endif
