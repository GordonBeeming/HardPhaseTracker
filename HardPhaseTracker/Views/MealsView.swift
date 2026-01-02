import SwiftUI

struct MealsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Meals", systemImage: "fork.knife")
                .navigationTitle("Meals")
        }
        .accessibilityIdentifier("tab.meals")
    }
}

#Preview {
    MealsView()
}
