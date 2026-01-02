import SwiftUI
import SwiftData

struct MealTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var settings: [AppSettings]

    let templateToEdit: MealTemplate?

    @State private var showUsedConfirm = false
    @State private var usedCount: Int = 0

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
            ComponentDraft(name: $0.name, grams: String($0.grams), unit: $0.unit ?? "g")
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
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                TextField("Name", text: $component.name)

                                Menu {
                                    ForEach(componentNameSuggestions, id: \.self) { suggestion in
                                        Button(suggestion) {
                                            $component.name.wrappedValue = suggestion
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityLabel("Choose existing component")
                            }

                            TextField("Amount", text: $component.grams)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)

                            Menu {
                                ForEach(FoodUnit.ordered(for: preferredUnitSystem)) { u in
                                    Button(u.label) {
                                        $component.unit.wrappedValue = u.rawValue
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    let unit = $component.unit.wrappedValue
                                    Text(FoodUnit(rawValue: unit)?.label ?? unit)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: 110, alignment: .trailing)
                            }
                            .accessibilityLabel("Unit")
                        }
                    }
                    .onDelete(perform: deleteComponents)

                    Button("Add Component") {
                        let unit = FoodUnit.defaultUnit(for: preferredUnitSystem)
                        components.append(ComponentDraft(name: "", grams: "", unit: unit.rawValue))
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
                        if let templateToEdit {
                            let all = (try? modelContext.fetch(FetchDescriptor<MealLogEntry>())) ?? []
                            usedCount = all.filter { $0.template === templateToEdit }.count
                            if usedCount > 0 {
                                showUsedConfirm = true
                                return
                            }
                        }

                        saveUpdatingExisting()
                        dismiss()
                    }
                    .accessibilityIdentifier("mealEditor.save")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .confirmationDialog(
            "This meal is used in \(usedCount) logged meal(s)",
            isPresented: $showUsedConfirm,
            titleVisibility: .visible
        ) {
            Button("Update existing logged meals") {
                saveUpdatingExisting()
                dismiss()
            }

            Button("Only apply to new meals") {
                saveAsNewTemplate()
                dismiss()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose whether edits should affect already-logged meals or only future meals.")
        }
    }

    private var preferredUnitSystem: UnitSystem {
        settings.first?.unitSystemEnum ?? .metric
    }

    private var componentNameSuggestions: [String] {
        let all = (try? modelContext.fetch(FetchDescriptor<MealComponent>())) ?? []
        let set = Set(all.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return set.sorted()
    }

    private func deleteComponents(at offsets: IndexSet) {
        components.remove(atOffsets: offsets)
    }

    private func saveUpdatingExisting() {
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
                .map { MealComponent(name: $0.name, grams: Double($0.grams) ?? 0, unit: $0.unit) }
        } else {
            let template = MealTemplate(
                name: name,
                protein: parsedProtein,
                carbs: parsedCarbs,
                fats: parsedFats,
                components: components
                    .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .map { MealComponent(name: $0.name, grams: Double($0.grams) ?? 0, unit: $0.unit) }
            )
            modelContext.insert(template)
        }

        try? modelContext.save()
    }

    private func saveAsNewTemplate() {
        let parsedProtein = Double(protein) ?? 0
        let parsedCarbs = Double(carbs) ?? 0
        let parsedFats = Double(fats) ?? 0

        let template = MealTemplate(
            name: name,
            protein: parsedProtein,
            carbs: parsedCarbs,
            fats: parsedFats,
            components: components
                .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { MealComponent(name: $0.name, grams: Double($0.grams) ?? 0, unit: $0.unit) }
        )
        modelContext.insert(template)
        try? modelContext.save()
    }
}

private struct ComponentDraft: Identifiable {
    let id = UUID()
    var name: String
    var grams: String
    var unit: String
}

#Preview {
    MealTemplateEditorView()
}
