//
//  HardPhaseTrackerApp.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import Foundation
import OSLog
import SwiftUI
import SwiftData

@main
struct HardPhaseTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
            ElectrolyteIntakeEntry.self,
            ElectrolyteTargetSetting.self,
            EatingWindowSchedule.self,
            AppSettings.self,
        ])

        let iCloudContainerId = "iCloud.com.gordonbeeming.HardPhaseTracker"

        do {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .private(iCloudContainerId))
            return try ModelContainer(for: schema, configurations: [cloud])
        } catch {
            Logger(subsystem: "HardPhaseTracker", category: "CloudKit")
                .error("CloudKit SwiftData store failed; falling back to local-only store: \(error.localizedDescription)")

            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

            let storeURL = appSupport.appendingPathComponent("default.store")
            let local = ModelConfiguration(schema: schema, url: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [local])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
