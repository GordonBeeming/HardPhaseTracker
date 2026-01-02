import SwiftData

@Model
final class AppSettings {
    var selectedSchedule: EatingWindowSchedule?

    init(selectedSchedule: EatingWindowSchedule? = nil) {
        self.selectedSchedule = selectedSchedule
    }
}
