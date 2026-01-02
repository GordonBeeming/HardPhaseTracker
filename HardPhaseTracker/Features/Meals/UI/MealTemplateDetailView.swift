import SwiftUI

struct MealTemplateDetailView: View {
    let template: MealTemplate
    @State private var isEditing = false

    var body: some View {
        List {
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
                    ForEach(template.components) { component in
                        HStack {
                            Text(component.name)
                            Spacer()
                            let unit = component.unit ?? "g"
                            Text("\(component.grams, specifier: "%.0f") \(unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
                    .accessibilityIdentifier("mealDetail.edit")
            }
        }
        .sheet(isPresented: $isEditing) {
            MealTemplateEditorView(template: template)
        }
    }
}
