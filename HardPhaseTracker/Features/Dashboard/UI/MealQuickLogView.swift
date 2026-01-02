import SwiftUI
import SwiftData

struct MealQuickLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]

    @State private var customTimeTemplate: MealTemplate?

    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button {
                        MealLogService.logMeal(template: template, at: .now, modelContext: modelContext)
                        dismiss()
                    } label: {
                        Text(template.name)
                    }
                    .swipeActions {
                        Button("Time…") {
                            customTimeTemplate = template
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $customTimeTemplate) { template in
                MealLogWithTimeView(template: template)
            }
        }
    }
}

private struct MealLogWithTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let template: MealTemplate
    @State private var timestamp: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Meal time", selection: $timestamp)
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        MealLogService.logMeal(template: template, at: timestamp, modelContext: modelContext)
                        dismiss()
                    }
                }
            }
        }
    }
}
