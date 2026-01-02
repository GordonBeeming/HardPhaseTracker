import Testing
@testable import HardPhaseTracker

struct DashboardOnboardingPolicyTests {
    @Test func onboardingWhenNoScheduleSelected() async throws {
        #expect(DashboardOnboardingPolicy.shouldShowOnboarding(selectedSchedule: nil) == true)
    }
}
