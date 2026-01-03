import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealTemplate.name)])
    private var templates: [MealTemplate]

    @State private var isAdding = false

    var body: some View {
        NavigationSplitView {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No meals yet",
                        systemImage: "fork.knife",
                        description: Text("Create your first meal template.")
                    )
                    .background(AppTheme.background(colorScheme))
                } else {
                    List {
                        ForEach(templates) { template in
                            NavigationLink {
                                MealTemplateDetailView(template: template)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: (template.kind == MealTemplateKind.electrolyte.rawValue) ? "drop.fill" : "fork.knife")
                                        .foregroundStyle(.secondary)
                                    Text(template.name)
                                }
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAdding = true
                    } label: {
                        Label("Add Meal", systemImage: "plus")
                    }
                    .accessibilityIdentifier("meals.add")
                }
            }
        } detail: {
            ContentUnavailableView("Select a meal", systemImage: "fork.knife")
        }
        .appScreen()
        .sheet(isPresented: $isAdding) {
            MealTemplateEditorView()
        }
        .accessibilityIdentifier("tab.meals")
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    MealsView()
}
