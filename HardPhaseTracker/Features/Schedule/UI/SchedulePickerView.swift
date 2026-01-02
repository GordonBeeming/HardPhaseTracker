import SwiftUI
import SwiftData

struct SchedulePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\EatingWindowSchedule.name)])
    private var schedules: [EatingWindowSchedule]

    @Query private var settings: [AppSettings]

    var body: some View {
        NavigationStack {
            List {
                ForEach(schedules) { schedule in
                    Button {
                        select(schedule)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(schedule.name)
                                Text(EatingWindowEvaluator.windowText(schedule: schedule))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.first?.selectedSchedule === schedule {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Eating Window")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func select(_ schedule: EatingWindowSchedule) {
        if let s = settings.first {
            s.selectedSchedule = schedule
        } else {
            modelContext.insert(AppSettings(selectedSchedule: schedule))
        }
        try? modelContext.save()
    }
}
