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
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "drop")
                }
                .tag(0)

            LogView()
                .tabItem {
                    Label("Log", systemImage: "calendar")
                }
                .tag(1)

            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(2)

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    // Only respond to horizontal swipes (more horizontal than vertical)
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 && selectedTab < 3 {
                            // Swipe left - go to next tab
                            selectedTab += 1
                        } else if horizontalAmount > 0 && selectedTab > 0 {
                            // Swipe right - go to previous tab
                            selectedTab -= 1
                        }
                    }
                }
        )
        .tint(AppTheme.primary(colorScheme))
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
