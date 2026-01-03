import SwiftUI
import SwiftData

struct MealQuickLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]

    @Query private var electrolyteEntries: [ElectrolyteIntakeEntry]

    let defaultTimestamp: Date
    let includeElectrolytes: Bool
    let onLogged: (() -> Void)?

    @State private var selectedTemplate: MealTemplate?

    init(defaultTimestamp: Date = .now, includeElectrolytes: Bool = false, onLogged: (() -> Void)? = nil) {
        self.defaultTimestamp = defaultTimestamp
        self.includeElectrolytes = includeElectrolytes
        self.onLogged = onLogged

        let day = Calendar.current.startOfDay(for: defaultTimestamp)
        _electrolyteEntries = Query(filter: #Predicate<ElectrolyteIntakeEntry> { $0.dayStart == day })
    }

    private func didLog() {
        selectedTemplate = nil
        onLogged?()
        dismiss()
    }

    private var visibleTemplates: [MealTemplate] {
        includeElectrolytes ? templates : templates.filter { $0.kind != MealTemplateKind.electrolyte.rawValue }
    }

    private func logElectrolyte(template: MealTemplate) {
        let day = Calendar.current.startOfDay(for: defaultTimestamp)

        let used = Set(electrolyteEntries.map { $0.slotIndex })
        let next = (0...max(used.max() ?? -1, 0) + 1).first(where: { !used.contains($0) }) ?? (used.max() ?? -1) + 1

        let entry = ElectrolyteIntakeEntry(timestamp: Date(), slotIndex: next, template: template)
        entry.dayStart = day
        modelContext.insert(entry)
        try? modelContext.save()
        didLog()
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleTemplates.isEmpty {
                    ContentUnavailableView(
                        "No meals created",
                        systemImage: "fork.knife",
                        description: Text("Create meals in the Meals tab, then come back here to log them.")
                    )
                } else {
                    List {
                        ForEach(visibleTemplates) { template in
                            Button {
                                if includeElectrolytes, template.kind == MealTemplateKind.electrolyte.rawValue {
                                    logElectrolyte(template: template)
                                } else {
                                    selectedTemplate = template
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: (template.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                        .foregroundStyle(.secondary)
                                    Text(template.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: (template.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                            .foregroundStyle(.secondary)
                        Text(template.name)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .accessibilityLabel(template.name)
                }
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
