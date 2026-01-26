import XCTest
import SwiftData
@testable import HardPhaseTracker

@MainActor
final class EatingWindowEvaluatorOverrideTests: XCTestCase {
    var testSchedule: EatingWindowSchedule!
    var calendar: Calendar!
    
    override func setUp() async throws {
        calendar = Calendar.current
        
        // Create test schedule: 12:00 PM - 8:00 PM, active Monday-Friday
        testSchedule = EatingWindowSchedule(
            name: "Test 16/8",
            startMinutes: 720,  // 12:00 PM
            endMinutes: 1200,   // 8:00 PM
            weekdayMask: 62,    // Mon-Fri (bits 2-6)
            isBuiltIn: false
        )
    }
    
    override func tearDown() async throws {
        testSchedule = nil
        calendar = nil
    }
    
    // MARK: - Schedule-Only Tests (Baseline)
    
    func testIsInWindow_NoOverride_InsideWindow() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2, hour: 14, minute: 0))! // Monday 2:00 PM
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: nil,
            calendar: calendar
        )
        
        XCTAssertTrue(isInWindow)
    }
    
    func testIsInWindow_NoOverride_OutsideWindow() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2, hour: 10, minute: 0))! // Monday 10:00 AM
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: nil,
            calendar: calendar
        )
        
        XCTAssertFalse(isInWindow)
    }
    
    func testIsInWindow_NoOverride_InactiveDay() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1, hour: 14, minute: 0))! // Sunday 2:00 PM
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: nil,
            calendar: calendar
        )
        
        XCTAssertFalse(isInWindow)
    }
    
    // MARK: - Skip Override Tests
    
    func testIsInWindow_SkipOverride_InsideScheduledWindow() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2, hour: 14, minute: 0))! // Monday 2:00 PM
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .skip,
            schedule: testSchedule
        )
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: override,
            calendar: calendar
        )
        
        XCTAssertFalse(isInWindow, "Skip override should prevent eating window even during scheduled time")
    }
    
    // MARK: - Eating Override Tests
    
    func testIsInWindow_EatingOverride_OnInactiveDay() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1, hour: 14, minute: 0))! // Sunday 2:00 PM
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: nil,  // Use schedule default
            endMinutes: nil
        )
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: override,
            calendar: calendar
        )
        
        XCTAssertTrue(isInWindow, "Eating override should enable window on inactive day")
    }
    
    func testIsInWindow_EatingOverride_CustomTimes_Inside() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2, hour: 15, minute: 0))! // Monday 3:00 PM
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: 840,  // 2:00 PM
            endMinutes: 1080    // 6:00 PM
        )
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: override,
            calendar: calendar
        )
        
        XCTAssertTrue(isInWindow, "Should be inside custom override window")
    }
    
    func testIsInWindow_EatingOverride_CustomTimes_Outside() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2, hour: 19, minute: 0))! // Monday 7:00 PM
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: 840,  // 2:00 PM
            endMinutes: 1080    // 6:00 PM
        )
        
        let isInWindow = EatingWindowEvaluator.isNowInWindow(
            schedule: testSchedule,
            now: testDate,
            override: override,
            calendar: calendar
        )
        
        XCTAssertFalse(isInWindow, "Should be outside custom override window")
    }
    
    // MARK: - Window Text Tests
    
    func testWindowText_NoOverride() throws {
        let text = EatingWindowEvaluator.windowText(schedule: testSchedule, override: nil)
        XCTAssertEqual(text, "12:00–20:00")
    }
    
    func testWindowText_OverrideWithCustomTimes() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2))!
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: 840,  // 2:00 PM (14:00)
            endMinutes: 1080    // 6:00 PM (18:00)
        )
        
        let text = EatingWindowEvaluator.windowText(schedule: testSchedule, override: override)
        XCTAssertEqual(text, "14:00–18:00")
    }
    
    func testWindowText_OverrideWithoutCustomTimes() throws {
        let testDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 2))!
        let normalizedDate = calendar.startOfDay(for: testDate)
        
        let override = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: nil,
            endMinutes: nil
        )
        
        let text = EatingWindowEvaluator.windowText(schedule: testSchedule, override: override)
        XCTAssertEqual(text, "12:00–20:00")
    }
}
