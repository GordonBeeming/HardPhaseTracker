import Foundation
import SwiftData

@Model
final class EatingWindowOverride {
    // CloudKit requires optional or default values for all properties
    var date: Date = Date()
    var overrideType: String = "eating"
    var startMinutes: Int?
    var endMinutes: Int?
    
    // CloudKit requires inverse relationships
    @Relationship(deleteRule: .nullify, inverse: \EatingWindowSchedule.overrides)
    var schedule: EatingWindowSchedule?
    
    init(date: Date, overrideType: OverrideType, schedule: EatingWindowSchedule?, startMinutes: Int? = nil, endMinutes: Int? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.overrideType = overrideType.rawValue
        self.schedule = schedule
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
    }
    
    var overrideTypeEnum: OverrideType {
        OverrideType(rawValue: overrideType) ?? .eating
    }
}

enum OverrideType: String, Codable {
    case eating = "eating"
    case skip = "skip"
}
