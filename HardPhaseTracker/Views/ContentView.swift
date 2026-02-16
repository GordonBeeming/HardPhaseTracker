//
//  ContentView.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    private enum RootTab: Hashable {
        case dashboard
        case log
        case meals
        case analysis
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var cloudKitSync = CloudKitSyncService()
    @State private var selectedTab: RootTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "drop")
                }
                .tag(RootTab.dashboard)

            LogView()
                .tabItem {
                    Label("Log", systemImage: "calendar")
                }
                .tag(RootTab.log)

            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(RootTab.meals)

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(RootTab.analysis)
        }
        .tint(AppTheme.primary(colorScheme))
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .task {
            SeedSchedulesService.seedIfNeeded(modelContext: modelContext)
            
            // Clean up old overrides (past dates)
            EatingWindowOverrideService.clearOldOverrides(modelContext: modelContext)
            
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
