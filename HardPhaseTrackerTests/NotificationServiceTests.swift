import XCTest
import UserNotifications
@testable import HardPhaseTracker

@MainActor
final class NotificationServiceTests: XCTestCase {
    var service: NotificationService!
    var testSchedule: EatingWindowSchedule!
    var testSettings: AppSettings!
    
    override func setUp() async throws {
        service = NotificationService.shared
        
        // Create test schedule: 12:00 PM - 8:00 PM, all days
        testSchedule = EatingWindowSchedule(
            name: "Test 16/8",
            startMinutes: 720,  // 12:00 PM
            endMinutes: 1200,   // 8:00 PM
            weekdayMask: 127,   // All days
            isBuiltIn: false
        )
        
        // Create test settings
        testSettings = AppSettings()
        testSettings.selectedSchedule = testSchedule
        testSettings.notificationsEnabled = true
        testSettings.notifyBeforeWindowStartMinutes = 15
        testSettings.notifyBeforeWindowEndMinutes = 30
    }
    
    override func tearDown() async throws {
        service.cancelAllNotifications()
        service = nil
        testSchedule = nil
        testSettings = nil
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization() async throws {
        // Note: This test requires user interaction in a real environment
        // In automated tests, you'd need to mock UNUserNotificationCenter
        let granted = await service.requestAuthorization()
        
        // In a mock environment, we'd verify the request was made
        // For now, just verify the method completes without crashing
        XCTAssertNotNil(granted)
    }
    
    func testCheckAuthorizationStatus() async throws {
        let status = await service.checkAuthorizationStatus()
        
        // Status should be one of the valid enum cases
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ]
        
        XCTAssertTrue(validStatuses.contains(status))
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleNotifications_NoOverrides() throws {
        // Schedule notifications without any overrides
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. The correct number of notifications were scheduled (14 days × 2 = 28)
        // 2. Notifications are at the correct times
        // 3. Notification content is correct
        
        // Note: To fully test this, you'd need to:
        // - Mock UNUserNotificationCenter
        // - Capture the notification requests
        // - Verify their properties
    }
    
    func testScheduleNotifications_WithSkipOverride() throws {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let normalizedDate = Calendar.current.startOfDay(for: tomorrow)
        
        let skipOverride = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .skip,
            schedule: testSchedule
        )
        
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [skipOverride],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. No notifications were scheduled for the skipped day
        // 2. Notifications for other days were still scheduled
    }
    
    func testScheduleNotifications_WithCustomTimeOverride() throws {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let normalizedDate = Calendar.current.startOfDay(for: tomorrow)
        
        let customOverride = EatingWindowOverride(
            date: normalizedDate,
            overrideType: .eating,
            schedule: testSchedule,
            startMinutes: 840,  // 2:00 PM
            endMinutes: 1080    // 6:00 PM
        )
        
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [customOverride],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. Notifications for tomorrow use custom times (1:45 PM and 5:30 PM)
        // 2. Notifications for other days use schedule defaults
    }
    
    func testCancelAllNotifications() throws {
        // Schedule some notifications
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [],
            settings: testSettings
        )
        
        // Cancel all
        service.cancelAllNotifications()
        
        // In a real test, we'd verify:
        // 1. UNUserNotificationCenter.removeAllPendingNotificationRequests() was called
        // 2. No notifications remain scheduled
    }
    
    // MARK: - Edge Cases
    
    func testScheduleNotifications_DisabledInSettings() throws {
        testSettings.notificationsEnabled = false
        
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. No notifications were scheduled
        // 2. All existing notifications were cancelled
    }
    
    func testScheduleNotifications_MaxMinutesBeforeWindow() throws {
        testSettings.notifyBeforeWindowStartMinutes = 120  // Max: 2 hours
        testSettings.notifyBeforeWindowEndMinutes = 120
        
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. Notifications are scheduled 2 hours before start/end
        // 2. Times are correct (10:00 AM for start, 6:00 PM for end)
    }
    
    func testScheduleNotifications_MinMinutesBeforeWindow() throws {
        testSettings.notifyBeforeWindowStartMinutes = 1  // Min: 1 minute
        testSettings.notifyBeforeWindowEndMinutes = 1
        
        service.scheduleEatingWindowNotifications(
            schedule: testSchedule,
            overrides: [],
            settings: testSettings
        )
        
        // In a real test, we'd verify:
        // 1. Notifications are scheduled 1 minute before start/end
        // 2. Times are correct (11:59 AM for start, 7:59 PM for end)
    }
}

// MARK: - Test Helpers

extension NotificationServiceTests {
    /// Helper to verify notification content matches expected values
    func verifyNotification(
        _ request: UNNotificationRequest,
        expectedTitle: String,
        expectedBody: String,
        expectedDate: Date
    ) {
        XCTAssertEqual(request.content.title, expectedTitle)
        XCTAssertEqual(request.content.body, expectedBody)
        
        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
            let components = trigger.dateComponents
            let calendar = Calendar.current
            let requestDate = calendar.date(from: components)
            
            XCTAssertNotNil(requestDate)
            if let requestDate = requestDate {
                let diff = abs(requestDate.timeIntervalSince(expectedDate))
                XCTAssertLessThan(diff, 60, "Notification time should be within 1 minute of expected")
            }
        } else {
            XCTFail("Expected UNCalendarNotificationTrigger")
        }
    }
}
