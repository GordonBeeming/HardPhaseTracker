import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var allLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]
    
    @Query private var allOverrides: [EatingWindowOverride]

    @State private var selectedDate: Date = .now
    @State private var isLoggingMeal = false
    @State private var isShowingSettings = false
    @State private var isEditingDayOverride = false

    var body: some View {
        NavigationStack {
            MealLogListView(entries: logsForSelectedDate, selectedDate: selectedDate, settings: settings.first) {
                AnyView(
                    VStack(spacing: 12) {
                        MealCalendarView(selectedDate: $selectedDate)
                        
                        // Show eating window status for today and future
                        EatingWindowDayStatusView(
                            date: selectedDate,
                            schedule: settings.first?.selectedSchedule,
                            override: overrideForSelectedDate
                        ) {
                            isEditingDayOverride = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                )
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isLoggingMeal = true
                    } label: {
                        Label("Log Meal", systemImage: "plus")
                    }

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .appScreen()
        .sheet(isPresented: $isLoggingMeal) {
            MealQuickLogView(defaultTimestamp: defaultLogTimestamp, includeElectrolytes: true) {
                isLoggingMeal = false
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isEditingDayOverride) {
            DayOverrideEditorSheet(
                date: selectedDate,
                schedule: settings.first?.selectedSchedule,
                existingOverride: overrideForSelectedDate
            )
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
    
    private var overrideForSelectedDate: EatingWindowOverride? {
        let cal = Calendar.current
        let normalizedDate = cal.startOfDay(for: selectedDate)
        return allOverrides.first { cal.isDate($0.date, inSameDayAs: normalizedDate) }
    }

}

#Preview {
    LogView()
}
