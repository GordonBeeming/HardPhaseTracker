import Foundation
import Testing
@testable import HardPhaseTracker

struct DateFormattingMealTimeTests {
    @Test func capturedModeAddsBadgeWhenDifferentFromDevice() async throws {
        let captured = TimeZone(secondsFromGMT: 10 * 3600)!.identifier
        let device = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 0)

        let text = DateFormatting.formatMealTime(
            date: date,
            capturedTimeZoneIdentifier: captured,
            displayMode: .captured,
            badgeStyle: .offset,
            offsetStyle: .utc,
            deviceTimeZone: device
        )

        #expect(text.contains("UTC+10"))
    }

    @Test func deviceModeDoesNotAddBadge() async throws {
        let captured = TimeZone(secondsFromGMT: 10 * 3600)!.identifier
        let device = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 0)

        let text = DateFormatting.formatMealTime(
            date: date,
            capturedTimeZoneIdentifier: captured,
            displayMode: .device,
            badgeStyle: .offset,
            offsetStyle: .utc,
            deviceTimeZone: device
        )

        #expect(!text.contains("UTC"))
        #expect(!text.contains("GMT"))
        #expect(!text.contains("+10"))
    }
}
