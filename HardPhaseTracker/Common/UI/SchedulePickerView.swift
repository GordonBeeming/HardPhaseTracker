import SwiftUI
import SwiftData

struct SchedulePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\EatingWindowSchedule.name)])
    private var schedules: [EatingWindowSchedule]

    @Query private var settings: [AppSettings]

    @State private var isAddingCustom = false
    @State private var editingSchedule: EatingWindowSchedule?
    @State private var showInUseDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isAddingCustom = true
                    } label: {
                        Label("Add custom schedule", systemImage: "plus")
                    }
                }

                Section {
                    let custom = schedules.filter { !$0.isBuiltIn }
                    let builtIn = schedules.filter { $0.isBuiltIn }

                    ForEach(custom + builtIn) { schedule in
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Edit") {
                                editingSchedule = schedule
                            }
                            .tint(.blue)

                            if schedule.isBuiltIn {
                                // built-in; no delete
                            } else {
                                Button("Delete", role: .destructive) {
                                    if settings.first?.selectedSchedule === schedule {
                                        showInUseDeleteAlert = true
                                        return
                                    }

                                    modelContext.delete(schedule)
                                    modelContext.saveLogged()
                                }
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
            .sheet(isPresented: $isAddingCustom) {
                ScheduleEditorView()
            }
            .sheet(item: $editingSchedule) { schedule in
                ScheduleEditorView(schedule: schedule)
            }
            .alert("Schedule in use", isPresented: $showInUseDeleteAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This schedule is currently selected on the Dashboard. Switch schedules first, then delete.")
            }
        }
    }

    private func select(_ schedule: EatingWindowSchedule) {
        if let s = settings.first {
            s.selectedSchedule = schedule
        } else {
            modelContext.insert(AppSettings(selectedSchedule: schedule))
        }
        modelContext.saveLogged()
    }
}
