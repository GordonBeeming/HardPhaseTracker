//
//  HardPhaseTrackerApp.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import SwiftUI
import SwiftData

@main
struct HardPhaseTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
