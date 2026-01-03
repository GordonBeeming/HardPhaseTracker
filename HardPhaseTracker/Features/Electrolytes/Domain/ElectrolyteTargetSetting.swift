import Foundation
import SwiftData

@Model
final class ElectrolyteTargetSetting {
    /// Start-of-day (local calendar) for when this setting becomes active.
    var effectiveDate: Date
    var servingsPerDay: Int

    init(effectiveDate: Date, servingsPerDay: Int) {
        self.effectiveDate = effectiveDate
        self.servingsPerDay = servingsPerDay
    }
}
