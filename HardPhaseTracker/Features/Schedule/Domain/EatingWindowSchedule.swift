import Foundation
import SwiftData

@Model
final class EatingWindowSchedule {
    var name: String
    var startMinutes: Int
    var endMinutes: Int
    var weekdayMask: Int
    var isBuiltIn: Bool

    init(name: String, startMinutes: Int, endMinutes: Int, weekdayMask: Int, isBuiltIn: Bool = false) {
        self.name = name
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.weekdayMask = weekdayMask
        self.isBuiltIn = isBuiltIn
    }
}

extension EatingWindowSchedule {
    // Bitmask uses Calendar weekday values 1...7 (1 = Sunday)
    func isActive(on weekday: Int) -> Bool {
        weekdayMask & (1 << weekday) != 0
    }

    static func mask(for weekdays: [Int]) -> Int {
        weekdays.reduce(0) { $0 | (1 << $1) }
    }
}
