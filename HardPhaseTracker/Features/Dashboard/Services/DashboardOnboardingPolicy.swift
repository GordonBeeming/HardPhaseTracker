import Foundation

enum DashboardOnboardingPolicy {
    static func shouldShowOnboarding(selectedSchedule: EatingWindowSchedule?) -> Bool {
        selectedSchedule == nil
    }
}
