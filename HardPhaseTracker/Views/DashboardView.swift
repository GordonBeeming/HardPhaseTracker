import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Dashboard", systemImage: "drop")
                .navigationTitle("Dashboard")
        }
        .accessibilityIdentifier("tab.dashboard")
    }
}

#Preview {
    DashboardView()
}
