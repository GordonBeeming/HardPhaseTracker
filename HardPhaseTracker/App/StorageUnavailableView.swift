import SwiftUI

struct StorageUnavailableView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Storage unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(message + "\n\nIf this persists, try reinstalling the app (Simulator: delete the app) to reset the local database.")
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
