import Foundation

enum MealTimeDisplayMode: String {
    case captured
    case device
}

enum MealTimeZoneBadgeStyle: String {
    case offset
    case abbrev
}

enum MealTimeOffsetStyle: String {
    case utc
    case plain
}

extension AppSettings {
    var mealTimeDisplayModeEnum: MealTimeDisplayMode {
        MealTimeDisplayMode(rawValue: mealTimeDisplayMode ?? "") ?? .captured
    }

    var mealTimeZoneBadgeStyleEnum: MealTimeZoneBadgeStyle {
        // Migration-safe mapping from older values.
        switch mealTimeZoneBadgeStyle ?? "" {
        case "abbrev": return .abbrev
        // retired options (keep mapping for migration-safety)
        case "offset", "both", "identifier": return .abbrev
        default: return .abbrev
        }
    }

    var mealTimeOffsetStyleEnum: MealTimeOffsetStyle {
        MealTimeOffsetStyle(rawValue: mealTimeOffsetStyle ?? "") ?? .utc
    }
}
