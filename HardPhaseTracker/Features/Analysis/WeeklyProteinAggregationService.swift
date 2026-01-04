import Foundation

struct WeeklyProteinSummary: Identifiable, Equatable {
    let id: UUID
    let weekStart: Date
    let weekEnd: Date
    let totalProteinGrams: Double
    let goalProteinGrams: Double

    init(weekStart: Date, weekEnd: Date, totalProteinGrams: Double, goalProteinGrams: Double) {
        self.id = UUID()
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.totalProteinGrams = totalProteinGrams
        self.goalProteinGrams = goalProteinGrams
    }
}

enum WeeklyProteinAggregationService {
    static func summaries(
        entries: [MealLogEntry],
        goalGrams: Double,
        now: Date = .now,
        weeks: Int = 4,
        calendar: Calendar = Calendar(identifier: .iso8601)
    ) -> [WeeklyProteinSummary] {
        guard weeks > 0 else { return [] }

        let goal = max(0, goalGrams)
        let currentWeek = weekInterval(containing: now, calendar: calendar)

        let mealEntries = entries.filter { entry in
            guard let template = entry.template else { return false }
            return template.kind != MealTemplateKind.electrolyte.rawValue
        }

        return (0..<weeks).compactMap { idx in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -idx, to: currentWeek.start) else { return nil }
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return nil }

            let total = mealEntries
                .filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }
                .reduce(0) { $0 + ($1.template?.protein ?? 0) }

            return WeeklyProteinSummary(
                weekStart: weekStart,
                weekEnd: weekEnd,
                totalProteinGrams: total,
                goalProteinGrams: goal
            )
        }
    }

    static func weekInterval(containing date: Date, calendar: Calendar = Calendar(identifier: .iso8601)) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 24 * 3600)
    }
}
