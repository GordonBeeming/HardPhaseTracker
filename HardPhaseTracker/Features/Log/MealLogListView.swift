import SwiftUI
import SwiftData

struct MealLogListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query private var electrolyteEntries: [ElectrolyteIntakeEntry]

    let entries: [MealLogEntry]
    let selectedDate: Date
    let settings: AppSettings?
    let header: (() -> AnyView)?

    init(entries: [MealLogEntry], selectedDate: Date, settings: AppSettings?, header: (() -> AnyView)? = nil) {
        self.entries = entries
        self.selectedDate = selectedDate
        self.settings = settings
        self.header = header

        let day = Calendar.current.startOfDay(for: selectedDate)
        _electrolyteEntries = Query(filter: #Predicate<ElectrolyteIntakeEntry> { $0.dayStart == day })
    }

    @State private var editingEntry: MealLogEntry?
    @State private var detailEntry: MealLogEntry?

    var body: some View {
        let grouped = group(entries: entries)

        let shouldShowElectrolytes = !electrolyteEntries.isEmpty

        let displayedGroups: [DayGroup] = {
            if grouped.isEmpty && shouldShowElectrolytes {
                return [DayGroup(day: Calendar.current.startOfDay(for: selectedDate), entries: [])]
            }
            return grouped
        }()

        let isEmptyState = entries.isEmpty && !shouldShowElectrolytes

        Group {
            if isEmptyState {
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
                }
            } else {
                List {
                    if let header {
                        Section {
                            header()
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppTheme.background(colorScheme))
                        }
                    }

                    ForEach(displayedGroups, id: \.day) { group in
                        Section(dayTitle(group.day)) {
                            let isSelectedDayGroup = Calendar.current.isDate(group.day, inSameDayAs: selectedDate)
                            let electrolyteRows = (shouldShowElectrolytes && isSelectedDayGroup) ? electrolyteEntries : []

                            let rows: [LogRow] = (electrolyteRows.map { LogRow.electrolyte($0) } + group.entries.map { LogRow.meal($0) })
                                .sorted { $0.timestamp < $1.timestamp }

                            ForEach(rows) { row in
                                switch row {
                                case .electrolyte(let e):
                                    HStack {
                                        Image(systemName: "drop.fill")
                                            .foregroundStyle(.secondary)

                                        Text(e.template?.name ?? "Electrolyte")

                                        Spacer()
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Delete", role: .destructive) {
                                            modelContext.delete(e)
                                            modelContext.saveLogged()
                                        }
                                    }

                                case .meal(let entry):
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

    private enum LogRow: Identifiable {
        case meal(MealLogEntry)
        case electrolyte(ElectrolyteIntakeEntry)

        var id: String {
            switch self {
            case .meal(let e):
                return "meal-\(e.persistentModelID)"
            case .electrolyte(let e):
                return "electrolyte-\(e.persistentModelID)"
            }
        }

        var timestamp: Date {
            switch self {
            case .meal(let e):
                return e.timestamp
            case .electrolyte(let e):
                return e.timestamp
            }
        }
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
