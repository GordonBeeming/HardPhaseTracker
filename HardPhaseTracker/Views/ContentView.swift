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

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "drop")
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
            SeedMealTemplatesService.seedIfNeeded(modelContext: modelContext)
            SeedSchedulesService.seedIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
}
