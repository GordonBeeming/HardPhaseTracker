import Foundation
import Testing
@testable import HardPhaseTracker

struct ElectrolyteIntakeEntryTests {
    @Test func dayStartIsStartOfDayForTimestamp() {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let timestamp = cal.date(bySettingHour: 15, minute: 30, second: 0, of: day)!

        let entry = ElectrolyteIntakeEntry(timestamp: timestamp, slotIndex: 0, template: nil)
        #expect(entry.dayStart == cal.startOfDay(for: timestamp))
    }
}
