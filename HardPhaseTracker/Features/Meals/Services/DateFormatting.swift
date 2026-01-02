import Foundation

enum DateFormatting {
    private static let mealDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func formatDurationShort(seconds: TimeInterval, maxUnits: Int = 2) -> String {
        let total = max(0, Int(seconds))
        let days = total / 86_400
        let hours = (total / 3_600) % 24
        let minutes = (total / 60) % 60
        let secs = total % 60

        let parts: [(Int, String)] = [
            (days, "d"),
            (hours, "h"),
            (minutes, "m"),
            (secs, "s")
        ]

        let nonZero = parts.filter { $0.0 > 0 }
        guard !nonZero.isEmpty else { return "0s" }

        return nonZero.prefix(max(1, maxUnits)).map { "\($0.0)\($0.1)" }.joined(separator: " ")
    }

    private static let mealTimeOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    static func formatMealTime(
        date: Date,
        capturedTimeZoneIdentifier: String,
        displayMode: MealTimeDisplayMode,
        badgeStyle: MealTimeZoneBadgeStyle,
        offsetStyle: MealTimeOffsetStyle,
        deviceTimeZone: TimeZone = .current
    ) -> String {
        let capturedTz = TimeZone(identifier: capturedTimeZoneIdentifier) ?? deviceTimeZone

        let displayTz: TimeZone = (displayMode == .device) ? deviceTimeZone : capturedTz
        mealDateTimeFormatter.timeZone = displayTz
        let base = mealDateTimeFormatter.string(from: date)

        guard displayMode == .captured else { return base }
        guard capturedTz.identifier != deviceTimeZone.identifier else { return base }

        let badge = timeZoneBadge(
            tz: capturedTz,
            at: date,
            style: badgeStyle,
            offsetStyle: offsetStyle
        )
        return badge.isEmpty ? base : "\(base) \(badge)"
    }

    static func formatMealClockTime(
        date: Date,
        capturedTimeZoneIdentifier: String,
        displayMode: MealTimeDisplayMode,
        badgeStyle: MealTimeZoneBadgeStyle,
        offsetStyle: MealTimeOffsetStyle,
        deviceTimeZone: TimeZone = .current
    ) -> String {
        let capturedTz = TimeZone(identifier: capturedTimeZoneIdentifier) ?? deviceTimeZone

        let displayTz: TimeZone = (displayMode == .device) ? deviceTimeZone : capturedTz
        mealTimeOnlyFormatter.timeZone = displayTz
        let base = mealTimeOnlyFormatter.string(from: date)

        guard displayMode == .captured else { return base }
        guard capturedTz.identifier != deviceTimeZone.identifier else { return base }

        let badge = timeZoneBadge(
            tz: capturedTz,
            at: date,
            style: badgeStyle,
            offsetStyle: offsetStyle
        )
        return badge.isEmpty ? base : "\(base) \(badge)"
    }

    private static func timeZoneBadge(
        tz: TimeZone,
        at date: Date,
        style: MealTimeZoneBadgeStyle,
        offsetStyle: MealTimeOffsetStyle
    ) -> String {
        let offset = offsetText(seconds: tz.secondsFromGMT(for: date), style: offsetStyle)
        let abbr = tz.abbreviation(for: date) ?? ""
        let id = tz.identifier

        switch style {
        case .offset:
            return "(\(offset))"
        case .abbrev:
            return abbr.isEmpty ? "" : "(\(abbr))"
        }
    }

    private static func offsetText(seconds: Int, style: MealTimeOffsetStyle) -> String {
        let sign = seconds >= 0 ? "+" : "-"
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60

        let hhmm = minutes == 0 ? "\(sign)\(hours)" : String(format: "%@%d:%02d", sign, hours, minutes)

        switch style {
        case .utc:
            return "UTC\(hhmm)"
        case .plain:
            return hhmm
        }
    }
}
