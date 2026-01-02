import SwiftUI
import SwiftData

struct MealLogListView: View {
    @Environment(\.modelContext) private var modelContext

    let entries: [MealLogEntry]
    let selectedDate: Date
    let settings: AppSettings?

    @State private var editingEntry: MealLogEntry?
    @State private var detailEntry: MealLogEntry?

    var body: some View {
        let grouped = group(entries: entries)

        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "fork.knife",
                    description: Text("Log a meal to see it here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(grouped, id: \.day) { group in
                        Section(dayTitle(group.day)) {
                            ForEach(group.entries) { entry in
                                Button {
                                    detailEntry = entry
                                } label: {
                                    HStack {
                                        Text(entry.template?.name ?? "Meal")
                                        Spacer()
                                        Text(timeText(for: entry))
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Edit") { editingEntry = entry }
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(entry)
                                        try? modelContext.save()
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(item: $editingEntry) { entry in
            MealLogEntryEditorView(entry: entry)
        }
        .sheet(item: $detailEntry) { entry in
            NavigationStack {
                MealLogEntryDetailView(entry: entry, settings: settings)
            }
        }
    }

    private var emptyTitle: String {
        let cal = Calendar.current
        return cal.isDateInToday(selectedDate) ? "No meals today" : "No meals on this day"
    }

    private struct DayGroup {
        let day: Date
        let entries: [MealLogEntry]
    }

    private func group(entries: [MealLogEntry]) -> [DayGroup] {
        let calendar = Calendar.current
        let dict = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        return dict
            .map { DayGroup(day: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.day > $1.day }
    }

    private func dayTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }

        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: day)
    }

    private func timeText(for entry: MealLogEntry) -> String {
        let displayMode = settings?.mealTimeDisplayModeEnum ?? .captured

        // Use time-only formatting for list rows.
        return DateFormatting.formatMealClockTime(
            date: entry.timestamp,
            capturedTimeZoneIdentifier: entry.timeZoneIdentifier,
            displayMode: displayMode,
            badgeStyle: .abbrev,
            offsetStyle: .utc
        )
    }
}
