import SwiftUI

struct MealTemplateDetailView: View {
    let template: MealTemplate
    @State private var isEditing = false
    @State private var isDuplicating = false

    var body: some View {
        List {
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
                    ForEach(template.componentsList) { component in
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

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        isDuplicating = true
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Actions")
            }
        }
        .sheet(isPresented: $isEditing) {
            MealTemplateEditorView(template: template)
        }
        .sheet(isPresented: $isDuplicating) {
            MealTemplateEditorView(duplicateFrom: template)
        }
    }
}
