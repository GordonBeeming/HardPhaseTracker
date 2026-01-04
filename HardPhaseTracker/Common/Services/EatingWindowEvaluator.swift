import Foundation

enum EatingWindowEvaluator {
    static func isNowInWindow(schedule: EatingWindowSchedule, now: Date = .now, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: now)
        guard schedule.isActive(on: weekday) else { return false }

        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        return minutes >= schedule.startMinutes && minutes <= schedule.endMinutes
    }

    static func windowText(schedule: EatingWindowSchedule) -> String {
        func hhmm(_ minutes: Int) -> String {
            let h = minutes / 60
            let m = minutes % 60
            return String(format: "%02d:%02d", h, m)
        }
        return "\(hhmm(schedule.startMinutes))–\(hhmm(schedule.endMinutes))"
    }
}
