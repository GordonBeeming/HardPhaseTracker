import SwiftUI

struct MealCalendarView: View {
    @Binding var selectedDate: Date

    var body: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .labelsHidden()
    }
}
