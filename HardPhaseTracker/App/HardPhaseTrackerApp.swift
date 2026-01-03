//
//  HardPhaseTrackerApp.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import Foundation
import SwiftUI
import SwiftData

@main
struct HardPhaseTrackerApp: App {
    @State private var container: ModelContainer?
    @State private var containerErrorMessage: String?

    init() {
        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
            ElectrolyteIntakeEntry.self,
            ElectrolyteTargetSetting.self,
            EatingWindowSchedule.self,
            AppSettings.self,
        ])

        let result = AppModelContainerProvider.make(
            schema: schema,
            iCloudContainerId: "iCloud.com.gordonbeeming.HardPhaseTracker"
        )

        switch result {
        case .success(let c):
            _container = State(initialValue: c)
            _containerErrorMessage = State(initialValue: nil)
        case .failure(let e):
            _container = State(initialValue: nil)
            _containerErrorMessage = State(initialValue: e.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .modelContainer(container)
            } else {
                StorageUnavailableView(
                    message: containerErrorMessage ?? "The app couldn't open its database.",
                    onRetry: reloadContainer
                )
            }
        }
    }

    private func reloadContainer() {
        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
            ElectrolyteIntakeEntry.self,
            ElectrolyteTargetSetting.self,
            EatingWindowSchedule.self,
            AppSettings.self,
        ])

        let result = AppModelContainerProvider.make(
            schema: schema,
            iCloudContainerId: "iCloud.com.gordonbeeming.HardPhaseTracker"
        )

        switch result {
        case .success(let c):
            container = c
            containerErrorMessage = nil
        case .failure(let e):
            container = nil
            containerErrorMessage = e.localizedDescription
        }
    }
}
