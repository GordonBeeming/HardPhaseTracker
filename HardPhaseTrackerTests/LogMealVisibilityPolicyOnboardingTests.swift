import Foundation
import Testing
@testable import HardPhaseTracker

struct LogMealVisibilityPolicyOnboardingTests {
    @Test func hidesWhenNoScheduleSelected() async throws {
        #expect(LogMealVisibilityPolicy.shouldShowPrimary(alwaysShow: false, showBeforeHours: 2.5, showAfterHours: 2.5, schedule: nil, now: .now) == false)
    }

    @Test func stillHidesEvenIfAlwaysShowWhenNoSchedule() async throws {
        #expect(LogMealVisibilityPolicy.shouldShowPrimary(alwaysShow: true, showBeforeHours: 2.5, showAfterHours: 2.5, schedule: nil, now: .now) == false)
    }
}
