import SwiftUI
import SwiftData

struct DashboardMealLogSummaryView: View {
    @Environment(\.modelContext) private var modelContext

    let entries: [MealLogEntry]
    let settings: AppSettings?

    @State private var editingEntry: MealLogEntry?
    @State private var detailEntry: MealLogEntry?
    @State private var actionsEntry: MealLogEntry?
    @State private var isShowingActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent meals")
                    .font(.headline)
                Spacer()
            }

            ForEach(group(entries: entries), id: \.day) { group in
                Text(dayTitle(group.day))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                ForEach(group.entries) { entry in
                    HStack {
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

                        Button {
                            actionsEntry = entry
                            isShowingActions = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    Divider()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .padding(.horizontal)
        .sheet(item: $editingEntry) { entry in
            MealLogEntryEditorView(entry: entry)
        }
        .sheet(item: $detailEntry) { entry in
            NavigationStack {
                MealLogEntryDetailView(entry: entry, settings: settings)
            }
        }
        .confirmationDialog("Meal actions", isPresented: $isShowingActions, presenting: actionsEntry) { entry in
            Button("Edit") { editingEntry = entry }
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {
                actionsEntry = nil
            }
        } message: { _ in
            EmptyView()
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

        return DateFormatting.formatMealClockTime(
            date: entry.timestamp,
            capturedTimeZoneIdentifier: entry.timeZoneIdentifier,
            displayMode: displayMode,
            badgeStyle: .abbrev,
            offsetStyle: .utc
        )
    }
}
