import Foundation

enum EatingWindowNavigator {
    static func nextWindowStart(schedule: EatingWindowSchedule, now: Date = .now, overrides: [EatingWindowOverride] = [], calendar: Calendar = .current) -> Date? {
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            
            // Check if this day has an override
            let normalizedDay = calendar.startOfDay(for: day)
            if let override = overrides.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDay) }) {
                // Skip days marked as skip
                if override.overrideTypeEnum == .skip { continue }
                
                // It's an eating day override
                let start = windowStart(for: schedule, on: day, override: override, calendar: calendar)
                if start > now { return start }
            } else {
                // No override - use schedule logic
                let weekday = calendar.component(.weekday, from: day)
                guard schedule.isActive(on: weekday) else { continue }

                let start = windowStart(for: schedule, on: day, override: nil, calendar: calendar)
                if start > now { return start }
            }
        }
        return nil
    }

    static func currentWindowRange(schedule: EatingWindowSchedule, now: Date = .now, override: EatingWindowOverride? = nil, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        // Check override first
        if let override = override {
            // Skip overrides mean no window today
            if override.overrideTypeEnum == .skip { return nil }
            
            // It's an eating day override
            let start = windowStart(for: schedule, on: now, override: override, calendar: calendar)
            let end = windowEnd(for: schedule, on: now, override: override, calendar: calendar)
            guard now >= start && now <= end else { return nil }
            return (start, end)
        }
        
        // No override - use schedule logic
        let weekday = calendar.component(.weekday, from: now)
        guard schedule.isActive(on: weekday) else { return nil }

        let start = windowStart(for: schedule, on: now, override: nil, calendar: calendar)
        let end = windowEnd(for: schedule, on: now, override: nil, calendar: calendar)
        guard now >= start && now <= end else { return nil }
        return (start, end)
    }

    static func previousWindowEnd(schedule: EatingWindowSchedule, now: Date = .now, overrides: [EatingWindowOverride] = [], calendar: Calendar = .current) -> Date? {
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            
            // Check if this day has an override
            let normalizedDay = calendar.startOfDay(for: day)
            if let override = overrides.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDay) }) {
                // Skip days marked as skip
                if override.overrideTypeEnum == .skip { continue }
                
                // It's an eating day override
                let end = windowEnd(for: schedule, on: day, override: override, calendar: calendar)
                if end < now { return end }
            } else {
                // No override - use schedule logic
                let weekday = calendar.component(.weekday, from: day)
                guard schedule.isActive(on: weekday) else { continue }

                let end = windowEnd(for: schedule, on: day, override: nil, calendar: calendar)
                if end < now { return end }
            }
        }
        return nil
    }

    private static func windowStart(for schedule: EatingWindowSchedule, on day: Date, override: EatingWindowOverride?, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let startMinutes = override?.startMinutes ?? schedule.startMinutes
        return calendar.date(byAdding: .minute, value: startMinutes, to: startOfDay) ?? startOfDay
    }

    private static func windowEnd(for schedule: EatingWindowSchedule, on day: Date, override: EatingWindowOverride?, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let endMinutes = override?.endMinutes ?? schedule.endMinutes
        return calendar.date(byAdding: .minute, value: endMinutes, to: startOfDay) ?? startOfDay
    }
}
