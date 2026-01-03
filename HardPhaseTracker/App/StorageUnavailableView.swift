import SwiftUI

struct StorageUnavailableView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Storage unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Retry", action: onRetry)
                }
            }
            .navigationTitle("HardPhase Tracker")
        }
    }
}

#Preview {
    StorageUnavailableView(message: "Example error", onRetry: {})
}
