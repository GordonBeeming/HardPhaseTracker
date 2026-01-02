import Foundation

enum DateFormatting {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func format(date: Date, timeZoneIdentifier: String) -> String {
        let tz = TimeZone(identifier: timeZoneIdentifier) ?? .current
        formatter.timeZone = tz
        return formatter.string(from: date)
    }
}
