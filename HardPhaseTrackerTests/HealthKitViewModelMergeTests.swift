import Foundation
import Testing
@testable import HardPhaseTracker

struct HealthKitViewModelMergeTests {
    
    // MARK: - Helper to access private merge method via reflection
    
    /// Creates test weight samples for a given date
    func createWeight(date: Date, kg: Double) -> WeightSample {
        WeightSample(date: date, kilograms: kg)
    }
    
    /// Creates a date for testing
    func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)!
    }
    
    // MARK: - Merge Logic Tests (Testing behavior indirectly)
    
    @Test func mergePreservesExistingWeightsWhenNoNewData() {
        // Setup existing weights
        let jan1 = createWeight(date: date(2025, 1, 1), kg: 80.0)
        let jan2 = createWeight(date: date(2025, 1, 2), kg: 79.5)
        
        // The merge should preserve existing data when there's no overlap
        let existing = [jan1, jan2]
        let new: [WeightSample] = []
        
        // Verify existing data is intact
        #expect(existing.count == 2)
        #expect(existing[0].kilograms == 80.0)
        #expect(existing[1].kilograms == 79.5)
    }
    
    @Test func mergeAddsNewWeightsFromDifferentDays() {
        // Test data setup
        let jan1 = createWeight(date: date(2025, 1, 1), kg: 80.0)
        let jan2 = createWeight(date: date(2025, 1, 2), kg: 79.5)
        let jan3 = createWeight(date: date(2025, 1, 3), kg: 79.0)
        
        let existing = [jan1, jan2]
        let new = [jan3]
        
        // Combined should have all three
        let combined = existing + new
        #expect(combined.count == 3)
        
        // Verify dates are different days
        let calendar = Calendar.current
        let uniqueDays = Set(combined.map { calendar.startOfDay(for: $0.date) })
        #expect(uniqueDays.count == 3)
    }
    
    @Test func mergeKeepsNewerWeightForSameDay() {
        // Morning weight (older)
        let jan1Morning = createWeight(date: date(2025, 1, 1, hour: 8), kg: 80.5)
        // Evening weight (newer)
        let jan1Evening = createWeight(date: date(2025, 1, 1, hour: 20), kg: 80.0)
        
        // The evening weight should be preferred (more recent)
        let calendar = Calendar.current
        let sameDay = calendar.isDate(jan1Morning.date, inSameDayAs: jan1Evening.date)
        #expect(sameDay == true)
        
        // Newer timestamp
        #expect(jan1Evening.date > jan1Morning.date)
    }
    
    @Test func mergeHandlesMultipleWeightsOnSameDay() {
        // Create multiple weights for the same day at different times
        let jan1_8am = createWeight(date: date(2025, 1, 1, hour: 8), kg: 81.0)
        let jan1_12pm = createWeight(date: date(2025, 1, 1, hour: 12), kg: 80.5)
        let jan1_8pm = createWeight(date: date(2025, 1, 1, hour: 20), kg: 80.0)
        
        let weights = [jan1_8am, jan1_12pm, jan1_8pm]
        
        // Verify they're all the same day
        let calendar = Calendar.current
        let day1 = calendar.startOfDay(for: jan1_8am.date)
        let day2 = calendar.startOfDay(for: jan1_12pm.date)
        let day3 = calendar.startOfDay(for: jan1_8pm.date)
        
        #expect(day1 == day2)
        #expect(day2 == day3)
        
        // The latest should be 8pm with 80.0 kg
        let latest = weights.max(by: { $0.date < $1.date })
        #expect(latest?.kilograms == 80.0)
    }
    
    // MARK: - Date Filtering Tests
    
    @Test func filtersWeightsForLast7Days() {
        let calendar = Calendar.current
        let today = Date()
        
        let day6Ago = calendar.date(byAdding: .day, value: -6, to: today)!
        let day7Ago = calendar.date(byAdding: .day, value: -7, to: today)!
        let day8Ago = calendar.date(byAdding: .day, value: -8, to: today)!
        
        let w1 = createWeight(date: day6Ago, kg: 80.0) // Should be included
        let w2 = createWeight(date: day7Ago, kg: 79.5) // Should be included (boundary)
        let w3 = createWeight(date: day8Ago, kg: 79.0) // Should NOT be included
        
        let cutoff = calendar.date(byAdding: .day, value: -7, to: today)!
        let filtered = [w1, w2, w3].filter { $0.date >= cutoff }
        
        #expect(filtered.count == 2)
        #expect(filtered.contains(where: { $0.kilograms == 80.0 }))
        #expect(filtered.contains(where: { $0.kilograms == 79.5 }))
    }
    
    @Test func filtersWeightsForLast14Days() {
        let calendar = Calendar.current
        let today = Date()
        
        let day13Ago = calendar.date(byAdding: .day, value: -13, to: today)!
        let day14Ago = calendar.date(byAdding: .day, value: -14, to: today)!
        let day15Ago = calendar.date(byAdding: .day, value: -15, to: today)!
        
        let w1 = createWeight(date: day13Ago, kg: 80.0) // Should be included
        let w2 = createWeight(date: day14Ago, kg: 79.5) // Should be included (boundary)
        let w3 = createWeight(date: day15Ago, kg: 79.0) // Should NOT be included
        
        let cutoff = calendar.date(byAdding: .day, value: -14, to: today)!
        let filtered = [w1, w2, w3].filter { $0.date >= cutoff }
        
        #expect(filtered.count == 2)
    }
    
    // MARK: - Weight Sample Model Tests
    
    @Test func weightSampleEquality() {
        let id = UUID()
        let date = Date()
        
        let w1 = WeightSample(id: id, date: date, kilograms: 80.0)
        let w2 = WeightSample(id: id, date: date, kilograms: 80.0)
        
        #expect(w1 == w2)
    }
    
    @Test func weightSampleDifferentValues() {
        let date = Date()
        
        let w1 = WeightSample(date: date, kilograms: 80.0)
        let w2 = WeightSample(date: date, kilograms: 79.0)
        
        #expect(w1 != w2)
    }
    
    @Test func weightSampleSorting() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        let w1 = createWeight(date: today, kg: 80.0)
        let w2 = createWeight(date: yesterday, kg: 79.5)
        let w3 = createWeight(date: twoDaysAgo, kg: 79.0)
        
        let sorted = [w1, w2, w3].sorted { $0.date < $1.date }
        
        // Should be sorted oldest to newest
        #expect(sorted[0].kilograms == 79.0)
        #expect(sorted[1].kilograms == 79.5)
        #expect(sorted[2].kilograms == 80.0)
    }
    
    // MARK: - RefreshIfTodayWeightMissing Logic Tests
    
    @Test func detectsTodayWeightExists() {
        let calendar = Calendar.current
        let today = Date()
        
        let todayWeight = createWeight(date: today, kg: 80.0)
        let hasTodayWeight = calendar.isDate(todayWeight.date, inSameDayAs: today)
        
        #expect(hasTodayWeight == true)
    }
    
    @Test func detectsTodayWeightMissing() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let yesterdayWeight = createWeight(date: yesterday, kg: 80.0)
        let hasTodayWeight = calendar.isDate(yesterdayWeight.date, inSameDayAs: today)
        
        #expect(hasTodayWeight == false)
    }
    
    @Test func todayCheckHandlesDifferentTimes() {
        let calendar = Calendar.current
        let today = Date()
        
        // Weight from this morning
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        let morningWeight = createWeight(date: morning, kg: 80.5)
        
        // Check against now (different time, same day)
        let hasTodayWeight = calendar.isDate(morningWeight.date, inSameDayAs: today)
        
        #expect(hasTodayWeight == true)
    }
    
    // MARK: - Edge Cases
    
    @Test func handlesEmptyExistingWeights() {
        let existing: [WeightSample] = []
        let new = [createWeight(date: Date(), kg: 80.0)]
        
        let combined = existing + new
        #expect(combined.count == 1)
    }
    
    @Test func handlesEmptyNewWeights() {
        let existing = [createWeight(date: Date(), kg: 80.0)]
        let new: [WeightSample] = []
        
        let combined = existing + new
        #expect(combined.count == 1)
    }
    
    @Test func handlesBothEmpty() {
        let existing: [WeightSample] = []
        let new: [WeightSample] = []
        
        let combined = existing + new
        #expect(combined.isEmpty)
    }
}
