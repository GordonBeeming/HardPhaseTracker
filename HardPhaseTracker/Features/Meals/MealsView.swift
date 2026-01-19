import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]
    
    @Query private var mealLogEntries: [MealLogEntry]

    @State private var isAdding = false
    @State private var isDuplicating = false
    @State private var templateToDuplicate: MealTemplate?
    @State private var templateToNavigateTo: MealTemplate?
    @State private var isShowingSettings = false
    @State private var selectedTemplate: MealTemplate?
    
    // Filter out templates that are only used for inline meals
    private var visibleTemplates: [MealTemplate] {
        templates.filter { template in
            // Keep templates that have no meal log entries (never used)
            // or have at least one non-inline entry (used as a real template)
            let entries = template.mealLogEntries ?? []
            return entries.isEmpty || entries.contains { !$0.isInline }
        }
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if visibleTemplates.isEmpty {
                    ContentUnavailableView(
                        "No meals yet",
                        systemImage: "fork.knife",
                        description: Text("Create your first meal template.")
                    )
                    .background(AppTheme.background(colorScheme))
                } else {
                    List(selection: $selectedTemplate) {
                        ForEach(visibleTemplates) { template in
                            NavigationLink(value: template) {
                                HStack(spacing: 10) {
                                    Image(systemName: (template.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                        .foregroundStyle(.secondary)
                                    Text(template.name)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    templateToDuplicate = template
                                    isDuplicating = true
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.background(colorScheme))
                }
            }
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add Meal", systemImage: "plus")
                    }
                    .accessibilityIdentifier("meals.add")

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        } detail: {
            if let selected = selectedTemplate {
                MealTemplateDetailView(template: selected)
            } else {
                ContentUnavailableView("Select a meal", systemImage: "fork.knife")
            }
        }
        .appScreen()
        .sheet(isPresented: $isAdding) {
            MealTemplateEditorView()
        }
        .sheet(isPresented: $isDuplicating) {
            // onDismiss: Navigate after sheet is fully dismissed
            if let template = templateToNavigateTo {
                selectedTemplate = template
                templateToNavigateTo = nil
            }
        } content: {
            if let template = templateToDuplicate {
                MealTemplateEditorView(duplicateFrom: template) { savedTemplate in
                    // Store for navigation after sheet dismisses
                    templateToNavigateTo = savedTemplate
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .accessibilityIdentifier("tab.meals")
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
        modelContext.saveLogged()
    }
}

#Preview {
    MealsView()
}
