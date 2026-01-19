import SwiftUI
import SwiftData

struct InlineMealLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let defaultTimestamp: Date
    let onLogged: (() -> Void)?
    
    @State private var mealName: String = ""
    @State private var timestamp: Date
    @State private var notes: String = ""
    
    init(defaultTimestamp: Date = .now, onLogged: (() -> Void)? = nil) {
        self.defaultTimestamp = defaultTimestamp
        self.onLogged = onLogged
        _timestamp = State(initialValue: defaultTimestamp)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Meal name", text: $mealName)
                        .accessibilityIdentifier("inlineMeal.name")
                }
                
                Section("Time") {
                    DatePicker("Meal time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Create a minimal template for the inline meal
                        let template = MealTemplate(
                            name: trimmedName,
                            protein: 0,
                            carbs: 0,
                            fats: 0,
                            kind: MealTemplateKind.meal.rawValue,
                            components: []
                        )
                        modelContext.insert(template)
                        
                        // Create the meal log entry marked as inline
                        let entry = MealLogEntry(
                            timestamp: timestamp,
                            template: template,
                            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                            isInline: true
                        )
                        
                        modelContext.insert(entry)
                        modelContext.saveLogged()
                        dismiss()
                        onLogged?()
                    }
                    .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
