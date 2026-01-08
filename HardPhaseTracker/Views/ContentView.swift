//
//  ContentView.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var cloudKitSync = CloudKitSyncService()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "drop")
                }

            LogView()
                .tabItem {
                    Label("Log", systemImage: "calendar")
                }

            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(AppTheme.primary(colorScheme))
        .task {
            SeedSchedulesService.seedIfNeeded(modelContext: modelContext)
            
            // Request CloudKit sync on app launch (if online and stale)
            cloudKitSync.requestSyncIfStale(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Also sync when app comes back to foreground
            cloudKitSync.requestSyncIfStale(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
}
