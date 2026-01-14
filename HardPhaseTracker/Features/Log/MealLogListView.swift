import SwiftUI
import SwiftData

struct MealLogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let entries: [MealLogEntry]
    let selectedDate: Date
    let settings: AppSettings?
    let header: (() -> AnyView)?

    init(entries: [MealLogEntry], selectedDate: Date, settings: AppSettings?, header: (() -> AnyView)? = nil) {
        self.entries = entries
        self.selectedDate = selectedDate
        self.settings = settings
        self.header = header
    }

    @State private var editingEntry: MealLogEntry?
    @State private var detailEntry: MealLogEntry?

    var body: some View {
        let grouped = group(entries: entries)

        Group {
            if entries.isEmpty {
                VStack(spacing: 0) {
                    if let header {
                        header()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "fork.knife",
                        description: Text("Log a meal to see it here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // Show electrolyte checklist even when no meals
                    ElectrolyteChecklistView(date: selectedDate, settings: settings)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            } else {
                List {
                    if let header {
                        Section {
                            header()
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }

                    ForEach(grouped, id: \.day) { group in
                        Section(dayTitle(group.day)) {
                            ForEach(group.entries) { entry in
                                Button {
                                    detailEntry = entry
                                } label: {
                                    HStack {
                                        Image(systemName: (entry.template?.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                            .foregroundStyle(.secondary)

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
                                        modelContext.saveLogged()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Show electrolyte checklist at the bottom
                    Section {
                        ElectrolyteChecklistView(date: selectedDate, settings: settings)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppTheme.background(colorScheme))
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
            .map { DayGroup(day: $0.key, entries: $0.value.sorted { $0.timestamp < $1.timestamp }) }
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
