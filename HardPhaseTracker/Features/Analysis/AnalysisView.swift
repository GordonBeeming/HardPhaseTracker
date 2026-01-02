import SwiftUI

struct AnalysisView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming soon",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Charts and analytics will arrive in a future milestone.")
            )
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
        .appScreen()
        .accessibilityIdentifier("tab.analysis")
    }
}

#Preview {
    AnalysisView()
}
