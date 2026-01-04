import Foundation
import HealthKit

enum HealthKitQuerySupport {
    static func startDateForLastDays(_ days: Int, now: Date = Date(), calendar: Calendar = .current) -> Date {
        precondition(days > 0)
        // “Last 7 days” includes today => start at start-of-day (days-1) days ago.
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) ?? startOfToday
    }

    static func mapWeight(_ sample: HKQuantitySample) -> WeightSample {
        let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        return WeightSample(date: sample.startDate, kilograms: kg)
    }

    static func mapBodyFat(_ sample: HKQuantitySample) -> BodyFatSample {
        // HealthKit stores % as a fraction when using .percent() (e.g. 0.20 == 20%).
        let fraction = sample.quantity.doubleValue(for: .percent())
        return BodyFatSample(date: sample.startDate, percent: fraction * 100)
    }

    static func aggregateSleepNights(samples: [HKCategorySample], nights: Int, calendar: Calendar = .current) -> [SleepNight] {
        var totalsByDay: [Date: TimeInterval] = [:]

        for s in samples where isAsleep(value: s.value) {
            let dayKey = calendar.startOfDay(for: s.endDate)
            totalsByDay[dayKey, default: 0] += max(0, s.endDate.timeIntervalSince(s.startDate))
        }

        return totalsByDay
            .map { SleepNight(date: $0.key, asleepSeconds: $0.value) }
            .sorted { $0.date > $1.date }
            .prefix(nights)
            .map { $0 }
    }

    static func isAsleep(value: Int) -> Bool {
        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        default:
            return false
        }
    }
}
