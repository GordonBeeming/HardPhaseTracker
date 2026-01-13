import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    @Query private var settings: [AppSettings]
    @Query(sort: [SortDescriptor(\MealTemplate.name)]) private var templates: [MealTemplate]
    @Query(sort: [SortDescriptor(\ElectrolyteTargetSetting.effectiveDate)]) private var electrolyteTargets: [ElectrolyteTargetSetting]

    private enum SectionTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case meals = "Meals"
        case electrolytes = "Electrolytes"
        case analysis = "Analysis"
        case health = "Health"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .dashboard: "rectangle.3.group"
            case .meals: "fork.knife"
            case .electrolytes: "drop"
            case .analysis: "chart.line.uptrend.xyaxis"
            case .health: "heart"
            }
        }
    }

    @State private var selectedTab: SectionTab? = .dashboard
    @StateObject private var health = HealthKitViewModel()
    @State private var isRefreshingHealth = false

    // Dashboard
    @State private var alwaysShowLogMeal = false
    @State private var beforeHours: Double = 0.5 // 30 minutes
    @State private var afterHours: Double = 2.5
    @State private var dashboardMealListCount: Int = 10

    // Meals / time
    @State private var mealTimeDisplayMode: MealTimeDisplayMode = .captured

    // Electrolytes
    @State private var electrolyteServingsPerDay: Int = 0
    @State private var electrolyteAskEachTime: Bool = false

    // Global
    @State private var unitSystem: UnitSystem = .metric

    // Analysis
    @State private var weeklyProteinGoalGrams: Int = 0

    // Health
    @State private var weightGoalDisplay: Double = 0 // Display value in user's unit
    @State private var healthMonitoringStartDate: Date = Date()
    @State private var healthDataMaxPullDays: Int = 90

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(SectionTab.allCases, selection: $selectedTab) { t in
                        Label(t.rawValue, systemImage: t.systemImage)
                    }
                    .navigationTitle("Settings")
                    .safeAreaInset(edge: .bottom) {
                        versionFooter
                    }
                } detail: {
                    settingsDetail(tab: currentTab)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            } else {
                NavigationStack {
                    List(SectionTab.allCases) { t in
                        NavigationLink(value: t) {
                            Label(t.rawValue, systemImage: t.systemImage)
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationDestination(for: SectionTab.self) { t in
                        settingsDetail(tab: t)
                    }
                    .safeAreaInset(edge: .bottom) {
                        versionFooter
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                }
            }
        }
        .onAppear {
            let current = settings.first ?? AppSettings()
            if settings.isEmpty { modelContext.insert(current) }

            alwaysShowLogMeal = current.alwaysShowLogMealButton
            beforeHours = current.logMealShowBeforeHours
            afterHours = current.logMealShowAfterHours

            mealTimeDisplayMode = current.mealTimeDisplayModeEnum
            // timezone badge style setting removed (only one supported style)
            dashboardMealListCount = current.dashboardMealListCount ?? 10

            unitSystem = current.unitSystemEnum

            weeklyProteinGoalGrams = Int(current.weeklyProteinGoalGrams ?? 0)

            let weightGoalKg = current.weightGoalKg ?? 0
            weightGoalDisplay = unitSystem == .metric ? weightGoalKg : weightGoalKg * 2.20462262

            healthMonitoringStartDate = current.healthMonitoringStartDate ?? Date()
            healthDataMaxPullDays = current.healthDataMaxPullDays ?? 90

            electrolyteServingsPerDay = ElectrolyteTargetService.servingsPerDay(for: Date(), targets: electrolyteTargets)
            electrolyteAskEachTime = (current.electrolyteSelectionMode ?? "fixed") == "askEachTime"

            Task { await health.refreshPermissionOnly() }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .health {
                Task { await health.refreshPermissionOnly() }
            }
        }
        .onChange(of: alwaysShowLogMeal) { _, _ in save() }
        .onChange(of: beforeHours) { _, _ in save() }
        .onChange(of: afterHours) { _, _ in save() }
        .onChange(of: dashboardMealListCount) { _, _ in save() }
        .onChange(of: mealTimeDisplayMode) { _, _ in save() }
        .onChange(of: electrolyteServingsPerDay) { _, newValue in
            ElectrolyteTargetService.upsertToday(servingsPerDay: newValue, modelContext: modelContext)
        }
        .onChange(of: electrolyteAskEachTime) { _, _ in save() }
        .onChange(of: weeklyProteinGoalGrams) { _, _ in save() }
        .onChange(of: unitSystem) { oldValue, newValue in
            // Convert weight goal display when unit system changes
            if oldValue != newValue {
                if newValue == .imperial {
                    // metric -> imperial
                    weightGoalDisplay = weightGoalDisplay * 2.20462262
                } else {
                    // imperial -> metric
                    weightGoalDisplay = weightGoalDisplay / 2.20462262
                }
            }
            save()
        }
        .onChange(of: weightGoalDisplay) { _, _ in save() }
        .onChange(of: healthMonitoringStartDate) { _, _ in save() }
        .onChange(of: healthDataMaxPullDays) { _, _ in save() }
    }

    private var currentTab: SectionTab {
        selectedTab ?? .dashboard
    }

    @ViewBuilder
    private func settingsDetail(tab: SectionTab) -> some View {
        Form {
            switch tab {
            case .dashboard:
                Section("Log Meal button") {
                    Toggle("Always show Log Meal", isOn: $alwaysShowLogMeal)

                    if !alwaysShowLogMeal {
                        LabeledContent("Show before window", value: hoursText(beforeHours))
                        Slider(value: $beforeHours, in: 0...6, step: 0.5)

                        LabeledContent("Show after window", value: hoursText(afterHours))
                        Slider(value: $afterHours, in: 0...6, step: 0.5)
                    }
                }

                Section("Meal list") {
                    Stepper(value: $dashboardMealListCount, in: 0...20) {
                        Text(dashboardMealListCount == 0 ? "Hide dashboard meal list" : "Show last \(dashboardMealListCount) meals")
                    }
                }

            case .meals:
                Section("Meal time display") {
                    Picker("Display meal times in", selection: $mealTimeDisplayMode) {
                        Text("Captured timezone").tag(MealTimeDisplayMode.captured)
                        Text("Device timezone").tag(MealTimeDisplayMode.device)
                    }

                    Text(exampleText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Units") {
                    Picker("Preferred units", selection: $unitSystem) {
                        Text("Metric").tag(UnitSystem.metric)
                        Text("Imperial").tag(UnitSystem.imperial)
                    }
                }

            case .electrolytes:
                Section("Daily target") {
                    Stepper(value: $electrolyteServingsPerDay, in: 0...12) {
                        Text(electrolyteServingsPerDay == 0 ? "Off" : "\(electrolyteServingsPerDay) servings per day")
                    }

                    Text("Changing this only affects today and future days.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Selection") {
                    Toggle("Ask me each time", isOn: $electrolyteAskEachTime)
                    Text("If enabled, ticking a serving will always ask which electrolyte you had.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Electrolyte templates") {
                    let electrolyteTemplates = templates.filter { $0.kind == MealTemplateKind.electrolyte.rawValue }

                    if electrolyteTemplates.isEmpty {
                        Text("No electrolyte templates yet. Create one in Meals and enable ‘Use as electrolyte’. ")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(electrolyteTemplates) { t in
                            Button {
                                toggleElectrolyteTemplate(t)
                            } label: {
                                HStack {
                                    Text(t.name)
                                    Spacer()
                                    if isElectrolyteTemplateSelected(t) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Selected templates are offered when you tick off a serving.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .analysis:
                Section("Weekly protein goal") {
                    Stepper(value: $weeklyProteinGoalGrams, in: 0...5000, step: 25) {
                        Text(weeklyProteinGoalGrams == 0 ? "Off" : "\(weeklyProteinGoalGrams) g per week")
                    }

                    Text("Used by Analysis → Protein. Set to 0 to disable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .health:
                Section("Weight goal") {
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("Weight goal", value: $weightGoalDisplay, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(unitSystem == .metric ? "kg" : "lb")
                            .foregroundStyle(.secondary)
                    }
                    
                    if weightGoalDisplay == 0 {
                        Text("Set your weight goal to optimize the dashboard chart view")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Health monitoring") {
                    DatePicker("Journey start date", selection: $healthMonitoringStartDate, displayedComponents: .date)
                    
                    Text("Only health data from this date onwards will be shown")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Picker("Max data to pull", selection: $healthDataMaxPullDays) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                        Text("180 days").tag(180)
                        Text("1 year").tag(365)
                    }
                    
                    Text("Limits how far back to query HealthKit for performance")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Health") {
                    switch health.permission {
                    case .notAvailable:
                        Text("Health data isn’t available on this device.")
                            .foregroundStyle(.secondary)

                    case .notDetermined:
                        Button("Connect to Apple Health") {
                            Task { await health.requestAccess() }
                        }

                        Text(health.isDisconnected ? "Disconnected in-app." : "Not connected yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                    case .denied:
                        Text("Access is denied. Enable it in Settings → Health → Data Access & Devices.")
                            .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }

                    case .authorized:
                        Text("Connected (read-only).")
                            .foregroundStyle(.secondary)
                    }

                    if let msg = health.errorMessage {
                        Text(msg)
                            .foregroundStyle(.secondary)
                    }
                }

                if health.permission == .authorized {
                    Section("Cached data") {
                        LabeledContent("Last updated", value: health.cacheUpdatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                        LabeledContent("Weight samples", value: "\(health.weightsLast7Days.count)")
                        LabeledContent("Sleep nights", value: "\(health.sleepLast7Nights.count)")

                        Button("Refresh from Apple Health") {
                            Task { 
                                isRefreshingHealth = true
                                await health.refresh(
                                    maxDays: healthDataMaxPullDays,
                                    startDate: healthMonitoringStartDate,
                                    minDisplayTime: 1.0
                                )
                                isRefreshingHealth = false
                            }
                        }
                        .disabled(isRefreshingHealth)
                        
                        if isRefreshingHealth {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Refreshing...")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Clear cached data", role: .destructive) {
                            health.clearCachedData()
                        }

                        Button("Disconnect Apple Health", role: .destructive) {
                            health.disconnect()
                        }

                        Text("Disconnecting here stops the app from reading Apple Health and clears local cached data. You can also revoke access in iOS Settings → Health.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(tab.rawValue)
        .safeAreaInset(edge: .bottom) {
            versionFooter
        }
        .task {
            if tab == .health {
                await health.refreshPermissionOnly()
            }
        }
    }

    private func save() {
        let current = settings.first ?? AppSettings()
        if settings.isEmpty { modelContext.insert(current) }

        current.alwaysShowLogMealButton = alwaysShowLogMeal
        current.logMealShowBeforeHours = beforeHours
        current.logMealShowAfterHours = afterHours

        current.dashboardMealListCount = dashboardMealListCount

        current.mealTimeDisplayMode = mealTimeDisplayMode.rawValue
        // current.mealTimeZoneBadgeStyle not user-configurable (single supported style)
        // current.mealTimeOffsetStyle removed

        current.electrolyteSelectionMode = electrolyteAskEachTime ? "askEachTime" : "fixed"

        current.unitSystem = unitSystem.rawValue
        current.weeklyProteinGoalGrams = Double(weeklyProteinGoalGrams)

        // Convert weight goal display to kg for storage
        let weightGoalKg = unitSystem == .metric ? weightGoalDisplay : weightGoalDisplay / 2.20462262
        current.weightGoalKg = weightGoalKg > 0 ? weightGoalKg : nil
        current.healthMonitoringStartDate = healthMonitoringStartDate
        current.healthDataMaxPullDays = healthDataMaxPullDays

        modelContext.saveLogged()
    }

    private var exampleText: String {
        // Example: captured tz differs from device tz
        let captured = TimeZone(secondsFromGMT: 10 * 3600)!.identifier
        let device = TimeZone(secondsFromGMT: -8 * 3600)!
        let date = Date(timeIntervalSince1970: 1_735_689_600) // stable sample

        return "Example: " + DateFormatting.formatMealTime(
            date: date,
            capturedTimeZoneIdentifier: captured,
            displayMode: mealTimeDisplayMode,
            badgeStyle: .abbrev,
            offsetStyle: .utc,
            deviceTimeZone: device
        )
    }

    private func toggleElectrolyteTemplate(_ template: MealTemplate) {
        let current = settings.first ?? AppSettings()
        if settings.isEmpty { modelContext.insert(current) }

        var list = current.electrolyteTemplates ?? []
        if let idx = list.firstIndex(where: { $0.persistentModelID == template.persistentModelID }) {
            list.remove(at: idx)
        } else {
            list.append(template)
        }
        current.electrolyteTemplates = list
        modelContext.saveLogged()
    }

    private func isElectrolyteTemplateSelected(_ template: MealTemplate) -> Bool {
        let current = settings.first
        return (current?.electrolyteTemplates ?? []).contains(where: { $0.persistentModelID == template.persistentModelID })
    }

    private func hoursText(_ hours: Double) -> String {
        if hours == 0 { return "Off" }
        if hours < 1 {
            return "\(Int(hours * 60)) minutes"
        }
        if hours == 1 { return "1 hour" }
        return String(format: "%.1f hours", hours)
    }
    
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text(AppVersion.fullVersionString)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("© 2026 Gordon Beeming")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    SettingsView()
}
