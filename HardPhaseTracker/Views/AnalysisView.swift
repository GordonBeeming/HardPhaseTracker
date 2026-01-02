import SwiftUI

struct AnalysisView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                .navigationTitle("Analysis")
        }
        .accessibilityIdentifier("tab.analysis")
    }
}

#Preview {
    AnalysisView()
}
