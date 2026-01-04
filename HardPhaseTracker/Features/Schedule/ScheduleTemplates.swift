import Foundation

enum ScheduleTemplates {
    static func defaults() -> [EatingWindowSchedule] {
        let allDays = EatingWindowSchedule.mask(for: [1,2,3,4,5,6,7])

        return [
            EatingWindowSchedule(name: "16/8 (12pm–8pm, daily)", startMinutes: 12*60, endMinutes: 20*60, weekdayMask: allDays, isBuiltIn: true),
            EatingWindowSchedule(name: "18/6 (2pm–8pm, daily)", startMinutes: 14*60, endMinutes: 20*60, weekdayMask: allDays, isBuiltIn: true),
            EatingWindowSchedule(name: "20/4 (4pm–8pm, daily)", startMinutes: 16*60, endMinutes: 20*60, weekdayMask: allDays, isBuiltIn: true),
            EatingWindowSchedule(name: "OMAD (6pm–7pm, daily)", startMinutes: 18*60, endMinutes: 19*60, weekdayMask: allDays, isBuiltIn: true)
        ]
    }
}
