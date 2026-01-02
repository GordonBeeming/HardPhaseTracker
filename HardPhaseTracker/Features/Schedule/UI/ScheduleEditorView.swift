import SwiftUI
import SwiftData

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var settings: [AppSettings]

    let scheduleToEdit: EatingWindowSchedule?

    @State private var name: String
    @State private var startTime: Date
    @State private var endTime: Date

    @State private var showBuiltInConfirm = false

    init(schedule: EatingWindowSchedule? = nil) {
        self.scheduleToEdit = schedule

        _name = State(initialValue: schedule?.name ?? "")

        let calendar = Calendar.current
        let now = Date()
        // Defaults for new schedules: 16/8 (12pm–8pm), empty title.
        let startMinutes = schedule?.startMinutes ?? (12 * 60)
        let endMinutes = schedule?.endMinutes ?? (20 * 60)

        _startTime = State(initialValue: calendar.date(bySettingHour: startMinutes / 60, minute: startMinutes % 60, second: 0, of: now) ?? now)
        _endTime = State(initialValue: calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: now) ?? now)

        let mask = schedule?.weekdayMask ?? EatingWindowSchedule.mask(for: [1,2,3,4,5,6,7])
        _weekdaySelections = State(initialValue: [
            1: (mask & (1 << 1)) != 0,
            2: (mask & (1 << 2)) != 0,
            3: (mask & (1 << 3)) != 0,
            4: (mask & (1 << 4)) != 0,
            5: (mask & (1 << 5)) != 0,
            6: (mask & (1 << 6)) != 0,
            7: (mask & (1 << 7)) != 0,
        ])
    }

    @State private var weekdaySelections: [Int: Bool]

    var body: some View {
        NavigationStack {
            Form {
                if scheduleToEdit?.isBuiltIn == true {
                    Section {
                        Label("Built-in template — saving will create a copy", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Name") {
                    TextField("Schedule name", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }

                Section("Eating window") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Days") {
                    Toggle("Sunday", isOn: binding(for: 1))
                    Toggle("Monday", isOn: binding(for: 2))
                    Toggle("Tuesday", isOn: binding(for: 3))
                    Toggle("Wednesday", isOn: binding(for: 4))
                    Toggle("Thursday", isOn: binding(for: 5))
                    Toggle("Friday", isOn: binding(for: 6))
                    Toggle("Saturday", isOn: binding(for: 7))
                }
            }
            .navigationTitle(scheduleToEdit == nil ? "Custom Schedule" : "Edit Schedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if scheduleToEdit?.isBuiltIn == true {
                            showBuiltInConfirm = true
                        } else {
                            save()
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "Built-in schedule",
                isPresented: $showBuiltInConfirm,
                titleVisibility: .visible
            ) {
                Button("Duplicate & Save") {
                    save(asCopy: true)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This is a built-in template. Saving will create a copy so the original stays unchanged.")
            }
        }
    }

    private func binding(for weekday: Int) -> Binding<Bool> {
        Binding(
            get: { weekdaySelections[weekday] ?? false },
            set: { weekdaySelections[weekday] = $0 }
        )
    }

    private func save(asCopy: Bool = false) {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: startTime)
        let end = calendar.dateComponents([.hour, .minute], from: endTime)

        let startMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let endMinutes = (end.hour ?? 0) * 60 + (end.minute ?? 0)

        let selectedWeekdays = weekdaySelections
            .filter { $0.value }
            .map { $0.key }

        let mask = EatingWindowSchedule.mask(for: selectedWeekdays)

        if let scheduleToEdit, !asCopy {
            scheduleToEdit.name = name
            scheduleToEdit.startMinutes = startMinutes
            scheduleToEdit.endMinutes = endMinutes
            scheduleToEdit.weekdayMask = mask
            try? modelContext.save()
            return
        }

        let baseName = scheduleToEdit?.name
        let finalName = (baseName != nil && name == baseName) ? "\(name) (Custom)" : name

        let schedule = EatingWindowSchedule(
            name: finalName,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            weekdayMask: mask,
            isBuiltIn: false
        )

        modelContext.insert(schedule)
        if let s = settings.first {
            s.selectedSchedule = schedule
        }
        try? modelContext.save()
    }
}

#Preview {
    ScheduleEditorView()
}
