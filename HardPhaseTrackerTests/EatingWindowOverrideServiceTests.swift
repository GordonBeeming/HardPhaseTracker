import XCTest
import SwiftData
@testable import HardPhaseTracker

@MainActor
final class EatingWindowOverrideServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testSchedule: EatingWindowSchedule!
    
    override func setUp() async throws {
        let schema = Schema([
            EatingWindowSchedule.self,
            EatingWindowOverride.self,
            AppSettings.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
        
        // Create test schedule
        testSchedule = EatingWindowSchedule(
            name: "Test 16/8",
            startMinutes: 720,  // 12:00 PM
            endMinutes: 1200,   // 8:00 PM
            weekdayMask: 127,   // All days
            isBuiltIn: false
        )
        modelContext.insert(testSchedule)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        testSchedule = nil
    }
    
    // MARK: - Create/Update Tests
    
    func testCreateOverride() throws {
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        
        EatingWindowOverrideService.createOrUpdateOverride(
            date: testDate,
            type: .eating,
            schedule: testSchedule,
            startMinutes: 840,  // 2:00 PM
            endMinutes: 1080,   // 6:00 PM
            modelContext: modelContext
        )
        
        let override = EatingWindowOverrideService.getOverride(for: testDate, modelContext: modelContext)
        
        XCTAssertNotNil(override)
        XCTAssertEqual(override?.overrideTypeEnum, .eating)
        XCTAssertEqual(override?.startMinutes, 840)
        XCTAssertEqual(override?.endMinutes, 1080)
    }
    
    func testUpdateExistingOverride() throws {
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        
        // Create initial override
        EatingWindowOverrideService.createOrUpdateOverride(
            date: testDate,
            type: .eating,
            schedule: testSchedule,
            startMinutes: 840,
            endMinutes: 1080,
            modelContext: modelContext
        )
        
        // Update to skip
        EatingWindowOverrideService.createOrUpdateOverride(
            date: testDate,
            type: .skip,
            schedule: testSchedule,
            startMinutes: nil,
            endMinutes: nil,
            modelContext: modelContext
        )
        
        let override = EatingWindowOverrideService.getOverride(for: testDate, modelContext: modelContext)
        
        XCTAssertNotNil(override)
        XCTAssertEqual(override?.overrideTypeEnum, .skip)
        XCTAssertNil(override?.startMinutes)
        XCTAssertNil(override?.endMinutes)
    }
    
    // MARK: - Read Tests
    
    func testGetOverrideForDate() throws {
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        
        EatingWindowOverrideService.createOrUpdateOverride(
            date: testDate,
            type: .eating,
            schedule: testSchedule,
            startMinutes: nil,
            endMinutes: nil,
            modelContext: modelContext
        )
        
        let found = EatingWindowOverrideService.getOverride(for: testDate, modelContext: modelContext)
        XCTAssertNotNil(found)
        
        let notFound = EatingWindowOverrideService.getOverride(
            for: Calendar.current.date(byAdding: .day, value: 1, to: testDate)!,
            modelContext: modelContext
        )
        XCTAssertNil(notFound)
    }
    
    func testGetOverridesInRange() throws {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 10))!
        
        // Create overrides for days 1, 5, and 10
        for day in [1, 5, 10] {
            let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: day))!
            EatingWindowOverrideService.createOrUpdateOverride(
                date: date,
                type: .eating,
                schedule: testSchedule,
                startMinutes: nil,
                endMinutes: nil,
                modelContext: modelContext
            )
        }
        
        let overrides = EatingWindowOverrideService.getOverrides(in: start...end, modelContext: modelContext)
        
        XCTAssertEqual(overrides.count, 3)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteOverride() throws {
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        
        EatingWindowOverrideService.createOrUpdateOverride(
            date: testDate,
            type: .eating,
            schedule: testSchedule,
            startMinutes: nil,
            endMinutes: nil,
            modelContext: modelContext
        )
        
        let override = EatingWindowOverrideService.getOverride(for: testDate, modelContext: modelContext)!
        EatingWindowOverrideService.deleteOverride(override, modelContext: modelContext)
        
        let deleted = EatingWindowOverrideService.getOverride(for: testDate, modelContext: modelContext)
        XCTAssertNil(deleted)
    }
    
    // MARK: - Cleanup Tests
    
    func testClearOldOverrides() throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        // Create overrides for yesterday, today, and tomorrow
        for date in [yesterday, today, tomorrow] {
            EatingWindowOverrideService.createOrUpdateOverride(
                date: date,
                type: .eating,
                schedule: testSchedule,
                startMinutes: nil,
                endMinutes: nil,
                modelContext: modelContext
            )
        }
        
        // Clear old overrides
        EatingWindowOverrideService.clearOldOverrides(modelContext: modelContext)
        
        // Yesterday should be deleted, today and tomorrow should remain
        XCTAssertNil(EatingWindowOverrideService.getOverride(for: yesterday, modelContext: modelContext))
        XCTAssertNotNil(EatingWindowOverrideService.getOverride(for: today, modelContext: modelContext))
        XCTAssertNotNil(EatingWindowOverrideService.getOverride(for: tomorrow, modelContext: modelContext))
    }
}
