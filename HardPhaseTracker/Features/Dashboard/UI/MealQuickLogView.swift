import SwiftUI
import SwiftData

struct MealQuickLogView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]

    let defaultTimestamp: Date
    let onLogged: (() -> Void)?

    @State private var selectedTemplate: MealTemplate?

    init(defaultTimestamp: Date = .now, onLogged: (() -> Void)? = nil) {
        self.defaultTimestamp = defaultTimestamp
        self.onLogged = onLogged
    }

    private func didLog() {
        selectedTemplate = nil
        onLogged?()
        dismiss()
    }

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No meals created",
                        systemImage: "fork.knife",
                        description: Text("Create meals in the Meals tab, then come back here to log them.")
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                Text(template.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                MealLogWithTimeView(
                    template: template,
                    defaultTimestamp: defaultTimestamp,
                    onLogged: didLog
                )
            }
        }
    }
}

private struct MealLogWithTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let template: MealTemplate
    let onLogged: (() -> Void)?

    @State private var timestamp: Date
    @State private var notes: String = ""

    init(template: MealTemplate, defaultTimestamp: Date, onLogged: (() -> Void)? = nil) {
        self.template = template
        self.onLogged = onLogged
        _timestamp = State(initialValue: defaultTimestamp)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time") {
                    DatePicker("Meal time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        MealLogService.logMeal(
                            template: template,
                            at: timestamp,
                            notes: trimmed.isEmpty ? nil : trimmed,
                            modelContext: modelContext
                        )
                        dismiss()
                        onLogged?()
                    }
                }
            }
        }
    }
}
