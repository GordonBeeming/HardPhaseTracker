import Foundation

enum EatingWindowNavigator {
    static func nextWindowStart(schedule: EatingWindowSchedule, now: Date = .now, calendar: Calendar = .current) -> Date? {
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard schedule.isActive(on: weekday) else { continue }

            let start = windowStart(for: schedule, on: day, calendar: calendar)
            if start > now { return start }
        }
        return nil
    }

    static func currentWindowRange(schedule: EatingWindowSchedule, now: Date = .now, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        let weekday = calendar.component(.weekday, from: now)
        guard schedule.isActive(on: weekday) else { return nil }

        let start = windowStart(for: schedule, on: now, calendar: calendar)
        let end = windowEnd(for: schedule, on: now, calendar: calendar)
        guard now >= start && now <= end else { return nil }
        return (start, end)
    }

    static func previousWindowEnd(schedule: EatingWindowSchedule, now: Date = .now, calendar: Calendar = .current) -> Date? {
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard schedule.isActive(on: weekday) else { continue }

            let end = windowEnd(for: schedule, on: day, calendar: calendar)
            if end < now { return end }
        }
        return nil
    }

    private static func windowStart(for schedule: EatingWindowSchedule, on day: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: schedule.startMinutes, to: startOfDay) ?? startOfDay
    }

    private static func windowEnd(for schedule: EatingWindowSchedule, on day: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: schedule.endMinutes, to: startOfDay) ?? startOfDay
    }
}
