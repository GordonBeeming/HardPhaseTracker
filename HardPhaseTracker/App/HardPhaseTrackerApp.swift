//
//  HardPhaseTrackerApp.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
//

import Foundation
import SwiftUI
import SwiftData
import UIKit

@main
struct HardPhaseTrackerApp: App {
    @State private var container: ModelContainer?
    @State private var containerErrorMessage: String?

    init() {
        configureSystemChrome()

        let schema = Schema([
            MealTemplate.self,
            MealComponent.self,
            MealLogEntry.self,
            ElectrolyteIntakeEntry.self,
            ElectrolyteTargetSetting.self,
            EatingWindowSchedule.self,
            EatingWindowOverride.self,
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
            EatingWindowOverride.self,
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

    private func configureSystemChrome() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        tabAppearance.shadowColor = UIColor.white.withAlphaComponent(0.12)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        navAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
