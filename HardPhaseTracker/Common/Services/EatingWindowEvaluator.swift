import Foundation

enum EatingWindowEvaluator {
    static func isNowInWindow(schedule: EatingWindowSchedule, now: Date = .now, override: EatingWindowOverride? = nil, calendar: Calendar = .current) -> Bool {
        // Check if there's an override for today
        if let override = override {
            // If it's a skip override, no eating window today
            if override.overrideTypeEnum == .skip {
                return false
            }
            
            // It's an eating override - use custom times or schedule defaults
            let startMin = override.startMinutes ?? schedule.startMinutes
            let endMin = override.endMinutes ?? schedule.endMinutes
            
            let comps = calendar.dateComponents([.hour, .minute], from: now)
            let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            
            return minutes >= startMin && minutes <= endMin
        }
        
        // No override - use schedule default logic
        let weekday = calendar.component(.weekday, from: now)
        guard schedule.isActive(on: weekday) else { return false }

        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        return minutes >= schedule.startMinutes && minutes <= schedule.endMinutes
    }

    static func windowText(schedule: EatingWindowSchedule, override: EatingWindowOverride? = nil) -> String {
        func hhmm(_ minutes: Int) -> String {
            let h = minutes / 60
            let m = minutes % 60
            return String(format: "%02d:%02d", h, m)
        }
        
        // If override has custom times, use those
        if let override = override, override.overrideTypeEnum == .eating {
            let startMin = override.startMinutes ?? schedule.startMinutes
            let endMin = override.endMinutes ?? schedule.endMinutes
            return "\(hhmm(startMin))–\(hhmm(endMin))"
        }
        
        // Otherwise use schedule defaults
        return "\(hhmm(schedule.startMinutes))–\(hhmm(schedule.endMinutes))"
    }
}
