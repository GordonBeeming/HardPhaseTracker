import SwiftUI
import SwiftData

struct MealLogEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: MealLogEntry
    let settings: AppSettings?

    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            Section("Time") {
                Text(
                    DateFormatting.formatMealTime(
                        date: entry.timestamp,
                        capturedTimeZoneIdentifier: entry.timeZoneIdentifier,
                        displayMode: settings?.mealTimeDisplayModeEnum ?? .captured,
                        badgeStyle: .abbrev,
                        offsetStyle: .utc
                    )
                )
            }

            if let template = entry.template {
                Section("Meal") {
                    NavigationLink(template.name) {
                        MealTemplateDetailView(template: template)
                            .navigationTitle(template.name)
                    }
                }

                if !template.components.isEmpty {
                    Section("Components") {
                        ForEach(template.components) { c in
                            HStack {
                                Text(c.name)
                                Spacer()
                                let unit = c.unit ?? "g"
                                Text("\(c.grams, specifier: "%.0f") \(unit)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let notes = entry.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section {
                Button("Delete meal", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .navigationTitle("Meal")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .confirmationDialog(
            "Delete this meal?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isEditing) {
            MealLogEntryEditorView(entry: entry)
        }
    }
}
