import Foundation
import SwiftData
import Testing
@testable import HardPhaseTracker

struct ElectrolyteTargetServiceTests {
    @Test func servingsPerDayUsesLatestEffectiveDate() {
        let cal = Calendar.current
        let day1 = cal.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let day2 = cal.date(byAdding: .day, value: 1, to: day1)!
        let day3 = cal.date(byAdding: .day, value: 2, to: day1)!

        let targets = [
            ElectrolyteTargetSetting(effectiveDate: day1, servingsPerDay: 2),
            ElectrolyteTargetSetting(effectiveDate: day3, servingsPerDay: 4),
        ]

        #expect(ElectrolyteTargetService.servingsPerDay(for: day1, targets: targets) == 2)
        #expect(ElectrolyteTargetService.servingsPerDay(for: day2, targets: targets) == 2)
        #expect(ElectrolyteTargetService.servingsPerDay(for: day3, targets: targets) == 4)

        // For dates before any configured target, fall back to most recent target
        let beforeAll = cal.date(byAdding: .day, value: -1, to: day1)!
        #expect(ElectrolyteTargetService.servingsPerDay(for: beforeAll, targets: targets) == 4)
    }

    @Test func upsertTodayDoesNotChangePastTargets() async throws {
        let schema = Schema([
            ElectrolyteTargetSetting.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        context.insert(ElectrolyteTargetSetting(effectiveDate: yesterday, servingsPerDay: 2))
        try context.save()

        ElectrolyteTargetService.upsertToday(servingsPerDay: 4, modelContext: context)

        let fetched = try context.fetch(FetchDescriptor<ElectrolyteTargetSetting>())
        #expect(fetched.count == 2)

        let past = fetched.first(where: { cal.isDate($0.effectiveDate, inSameDayAs: yesterday) })
        let current = fetched.first(where: { cal.isDate($0.effectiveDate, inSameDayAs: today) })

        #expect(past?.servingsPerDay == 2)
        #expect(current?.servingsPerDay == 4)

        #expect(ElectrolyteTargetService.servingsPerDay(for: yesterday, targets: fetched) == 2)
        #expect(ElectrolyteTargetService.servingsPerDay(for: today, targets: fetched) == 4)
    }
    
    @Test func servingsPerDayReturnsZeroForEmptyTargets() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        #expect(ElectrolyteTargetService.servingsPerDay(for: today, targets: []) == 0)
    }
}
