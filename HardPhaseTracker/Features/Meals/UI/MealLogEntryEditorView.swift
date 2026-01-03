import SwiftUI
import SwiftData

struct MealLogEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var settings: [AppSettings]

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]

    private var mealTemplates: [MealTemplate] {
        templates.filter { $0.kind != MealTemplateKind.electrolyte.rawValue }
    }

    let entry: MealLogEntry

    @State private var timestamp: Date
    @State private var notes: String
    @State private var selectedTemplate: MealTemplate?

    init(entry: MealLogEntry) {
        self.entry = entry
        _timestamp = State(initialValue: entry.timestamp)
        _notes = State(initialValue: entry.notes ?? "")
        _selectedTemplate = State(initialValue: entry.template)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(mealTemplates) { t in
                            Label(t.name, systemImage: (t.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                .tag(Optional(t))
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Meal time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.timeZone, editorTimeZone)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Edit meal")
            .onAppear {
                if selectedTemplate == nil {
                    selectedTemplate = mealTemplates.first
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let selectedTemplate else { return }
                        entry.timestamp = timestamp
                        let tz = TimeZone(identifier: entry.timeZoneIdentifier) ?? .current
                        entry.utcOffsetSeconds = tz.secondsFromGMT(for: timestamp)
                        entry.template = selectedTemplate
                        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
                        modelContext.saveLogged()
                        dismiss()
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
        }
    }

    private var editorTimeZone: TimeZone {
        let displayMode = settings.first?.mealTimeDisplayModeEnum ?? .captured
        switch displayMode {
        case .device:
            return .current
        case .captured:
            return TimeZone(identifier: entry.timeZoneIdentifier) ?? .current
        }
    }
}
