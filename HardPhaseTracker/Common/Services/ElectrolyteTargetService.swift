import Foundation
import SwiftData

enum ElectrolyteTargetService {
    static func servingsPerDay(for date: Date, targets: [ElectrolyteTargetSetting]) -> Int {
        let day = Calendar.current.startOfDay(for: date)
        return targets
            .filter { $0.effectiveDate <= day }
            .max(by: { $0.effectiveDate < $1.effectiveDate })?
            .servingsPerDay ?? 0
    }

    /// Updates today's target (or creates a new effective-today target).
    /// Past days remain governed by earlier effective dates.
    static func upsertToday(servingsPerDay: Int, modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let all = (try? modelContext.fetch(FetchDescriptor<ElectrolyteTargetSetting>())) ?? []

        if let existing = all.first(where: { Calendar.current.isDate($0.effectiveDate, inSameDayAs: today) }) {
            existing.effectiveDate = today
            existing.servingsPerDay = servingsPerDay
        } else {
            modelContext.insert(ElectrolyteTargetSetting(effectiveDate: today, servingsPerDay: servingsPerDay))
        }

        modelContext.saveLogged()
    }
}
