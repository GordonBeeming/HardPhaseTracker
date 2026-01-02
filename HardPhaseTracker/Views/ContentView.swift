//
//  ContentView.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
}
