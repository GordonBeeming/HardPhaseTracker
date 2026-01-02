import Foundation
import SwiftData

enum SeedSchedulesService {
    private static let seedKey = "didSeedSchedules_v1"

    static func seedIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        let count = (try? modelContext.fetchCount(FetchDescriptor<EatingWindowSchedule>())) ?? 0
        if count == 0 {
            ScheduleTemplates.defaults().forEach { modelContext.insert($0) }
        }

        let settingsCount = (try? modelContext.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if settingsCount == 0 {
            let firstSchedule = try? modelContext.fetch(FetchDescriptor<EatingWindowSchedule>()).first
            modelContext.insert(AppSettings(selectedSchedule: firstSchedule))
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: seedKey)
    }
}
