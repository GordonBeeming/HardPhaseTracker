import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var allLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]

    @State private var selectedDate: Date = .now
    @State private var isLoggingMeal = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MealCalendarView(selectedDate: $selectedDate)
                    .padding(.horizontal)

                MealLogListView(entries: logsForSelectedDate, selectedDate: selectedDate, settings: settings.first)
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isLoggingMeal = true
                    } label: {
                        Label("Log Meal", systemImage: "plus")
                    }
                }
            }
        }
        .appScreen()
        .sheet(isPresented: $isLoggingMeal) {
            MealQuickLogView(defaultTimestamp: defaultLogTimestamp, includeElectrolytes: true) {
                isLoggingMeal = false
            }
        }
        .accessibilityIdentifier("tab.log")
    }

    private var logsForSelectedDate: [MealLogEntry] {
        let cal = Calendar.current
        return allLogs.filter { cal.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }

    private var defaultLogTimestamp: Date {
        let cal = Calendar.current
        let now = Date()
        let t = cal.dateComponents([.hour, .minute], from: now)
        return cal.date(bySettingHour: t.hour ?? 12, minute: t.minute ?? 0, second: 0, of: selectedDate) ?? selectedDate
    }

}

#Preview {
    LogView()
}
