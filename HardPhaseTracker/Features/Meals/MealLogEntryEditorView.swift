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
    @State private var inlineMealName: String

    init(entry: MealLogEntry) {
        self.entry = entry
        _timestamp = State(initialValue: entry.timestamp)
        _notes = State(initialValue: entry.notes ?? "")
        _selectedTemplate = State(initialValue: entry.template)
        _inlineMealName = State(initialValue: entry.template?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    if entry.isInline {
                        // For inline meals, edit the template name directly
                        TextField("Meal name", text: $inlineMealName)
                    } else {
                        // For regular meals, pick from templates
                        Picker("Template", selection: $selectedTemplate) {
                            ForEach(mealTemplates) { t in
                                Label(t.name, systemImage: (t.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                    .tag(Optional(t))
                            }
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
                        entry.timestamp = timestamp
                        let tz = TimeZone(identifier: entry.timeZoneIdentifier) ?? .current
                        entry.utcOffsetSeconds = tz.secondsFromGMT(for: timestamp)
                        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
                        
                        if entry.isInline {
                            // Update the inline template's name
                            entry.template?.name = inlineMealName.trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            // Update the template reference
                            guard let selectedTemplate else { return }
                            entry.template = selectedTemplate
                        }
                        
                        modelContext.saveLogged()
                        dismiss()
                    }
                    .disabled(entry.isInline ? inlineMealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : selectedTemplate == nil)
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
