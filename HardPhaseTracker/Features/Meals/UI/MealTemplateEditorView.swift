import SwiftUI
import SwiftData

struct MealTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let templateToEdit: MealTemplate?

    @State private var name: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fats: String
    @State private var components: [ComponentDraft]

    init(template: MealTemplate? = nil) {
        self.templateToEdit = template

        _name = State(initialValue: template?.name ?? "")
        _protein = State(initialValue: template.map { String($0.protein) } ?? "")
        _carbs = State(initialValue: template.map { String($0.carbs) } ?? "")
        _fats = State(initialValue: template.map { String($0.fats) } ?? "")
        _components = State(initialValue: template?.components.map {
            ComponentDraft(name: $0.name, grams: String($0.grams))
        } ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Meal Name", text: $name)
                        .accessibilityIdentifier("mealEditor.name")

                    TextField("Protein", text: $protein)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("mealEditor.protein")

                    TextField("Carbs", text: $carbs)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("mealEditor.carbs")

                    TextField("Fats", text: $fats)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("mealEditor.fats")
                }

                Section("Components") {
                    ForEach($components) { $component in
                        HStack {
                            TextField("Name", text: $component.name)
                            TextField("g", text: $component.grams)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                        }
                    }
                    .onDelete(perform: deleteComponents)

                    Button("Add Component") {
                        components.append(ComponentDraft(name: "", grams: ""))
                    }
                    .accessibilityIdentifier("mealEditor.addComponent")
                }
            }
            .navigationTitle(templateToEdit == nil ? "New Meal" : "Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .accessibilityIdentifier("mealEditor.save")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func deleteComponents(at offsets: IndexSet) {
        components.remove(atOffsets: offsets)
    }

    private func save() {
        let parsedProtein = Double(protein) ?? 0
        let parsedCarbs = Double(carbs) ?? 0
        let parsedFats = Double(fats) ?? 0

        if let templateToEdit {
            templateToEdit.name = name
            templateToEdit.protein = parsedProtein
            templateToEdit.carbs = parsedCarbs
            templateToEdit.fats = parsedFats

            templateToEdit.components.forEach { modelContext.delete($0) }
            templateToEdit.components = components
                .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { MealComponent(name: $0.name, grams: Double($0.grams) ?? 0) }
        } else {
            let template = MealTemplate(
                name: name,
                protein: parsedProtein,
                carbs: parsedCarbs,
                fats: parsedFats,
                components: components
                    .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .map { MealComponent(name: $0.name, grams: Double($0.grams) ?? 0) }
            )
            modelContext.insert(template)
        }

        try? modelContext.save()
    }
}

private struct ComponentDraft: Identifiable {
    let id = UUID()
    var name: String
    var grams: String
}

#Preview {
    MealTemplateEditorView()
}
