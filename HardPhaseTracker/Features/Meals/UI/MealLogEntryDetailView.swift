import SwiftUI

struct MealLogEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let entry: MealLogEntry
    let settings: AppSettings?

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
                    Text(template.name)
                }

                Section("Macros") {
                    LabeledContent("Protein", value: String(template.protein))
                    LabeledContent("Carbs", value: String(template.carbs))
                    LabeledContent("Fats", value: String(template.fats))
                }

                Section("Components") {
                    if template.components.isEmpty {
                        Text("No components")
                            .foregroundStyle(.secondary)
                    } else {
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
        }
        .navigationTitle("Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}
