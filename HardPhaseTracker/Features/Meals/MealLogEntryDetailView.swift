import SwiftUI

struct MealLogEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: MealLogEntry
    let settings: AppSettings?
    
    @State private var showConvertToRecipeConfirm = false
    @State private var showConvertToInlineConfirm = false

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
                HStack(spacing: 10) {
                    Image(systemName: entry.isInline ? "note.text" : ((template.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife"))
                        .foregroundStyle(.secondary)
                    Text(template.name)
                }
            }

            // Only show macros and components for non-inline meals
            if !entry.isInline {
                Section("Macros") {
                    LabeledContent("Protein", value: String(template.protein))
                    LabeledContent("Carbs", value: String(template.carbs))
                    LabeledContent("Fats", value: String(template.fats))
                }

                Section("Components") {
                    if template.componentsList.isEmpty {
                        Text("No components")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(template.componentsList) { c in
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
        }

            if let notes = entry.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            
            // Add conversion options menu
            if let template = entry.template {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if entry.isInline {
                            Button {
                                showConvertToRecipeConfirm = true
                            } label: {
                                Label("Convert to Recipe", systemImage: "fork.knife")
                            }
                        } else if canConvertToInline() {
                            Button {
                                showConvertToInlineConfirm = true
                            } label: {
                                Label("Convert to Inline", systemImage: "note.text")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Actions")
                }
            }
        }
        .confirmationDialog("Convert to Recipe", isPresented: $showConvertToRecipeConfirm) {
            Button("Convert to Recipe") {
                convertInlineToRecipe()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This meal will become a reusable recipe and appear in the Meals tab. You can add macros and components to it later.")
        }
        .confirmationDialog("Convert to Inline", isPresented: $showConvertToInlineConfirm) {
            Button("Convert to Inline") {
                convertRecipeToInline()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will hide this meal from the Meals tab. Since it has no macros or components, it makes sense as a one-time inline meal.")
        }
    }
    
    private func canConvertToInline() -> Bool {
        guard let template = entry.template, !entry.isInline else { return false }
        
        // Can only convert if template has no macros and no components
        return template.protein == 0 && 
               template.carbs == 0 && 
               template.fats == 0 && 
               template.componentsList.isEmpty
    }
    
    private func convertInlineToRecipe() {
        // Simply toggle the isInline flag
        entry.isInline = false
        modelContext.saveLogged()
        dismiss()
    }
    
    private func convertRecipeToInline() {
        // Simply toggle the isInline flag
        entry.isInline = true
        modelContext.saveLogged()
        dismiss()
    }
}
