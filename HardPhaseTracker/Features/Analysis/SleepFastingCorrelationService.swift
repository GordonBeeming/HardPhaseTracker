import Foundation

struct SleepFastingCorrelationRow: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let asleepSeconds: TimeInterval
    let fastingSecondsAtWake: TimeInterval?

    init(date: Date, asleepSeconds: TimeInterval, fastingSecondsAtWake: TimeInterval?) {
        self.id = UUID()
        self.date = date
        self.asleepSeconds = asleepSeconds
        self.fastingSecondsAtWake = fastingSecondsAtWake
    }
}

enum SleepFastingCorrelationService {
    static func rows(
        sleepNights: [SleepNight],
        mealEntries: [MealLogEntry],
        wakeOffsetHours: Double = 6
    ) -> [SleepFastingCorrelationRow] {
        let mealsAscending = mealEntries
            .filter { entry in
                guard let template = entry.template else { return false }
                return template.kind != MealTemplateKind.electrolyte.rawValue
            }
            .sorted { $0.timestamp < $1.timestamp }

        return sleepNights
            .sorted { $0.date > $1.date }
            .map { night in
                let wakeDate = night.date.addingTimeInterval(wakeOffsetHours * 3600)
                let lastMeal = mealsAscending.last(where: { $0.timestamp <= wakeDate })
                let fasting = lastMeal.map { max(0, wakeDate.timeIntervalSince($0.timestamp)) }

                return SleepFastingCorrelationRow(
                    date: night.date,
                    asleepSeconds: night.asleepSeconds,
                    fastingSecondsAtWake: fasting
                )
            }
    }
}
