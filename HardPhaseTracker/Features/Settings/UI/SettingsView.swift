import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var settings: [AppSettings]

    private enum SectionTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case meals = "Meals"

        var id: String { rawValue }
    }

    @State private var tab: SectionTab = .dashboard

    // Dashboard
    @State private var alwaysShowLogMeal = false
    @State private var beforeHours: Double = 0.5 // 30 minutes
    @State private var afterHours: Double = 2.5
    @State private var dashboardMealListCount: Int = 10

    // Meals / time
    @State private var mealTimeDisplayMode: MealTimeDisplayMode = .captured

    // Global
    @State private var unitSystem: UnitSystem = .metric

    var body: some View {
        NavigationStack {
            Form {
                Picker("Section", selection: $tab) {
                    ForEach(SectionTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

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
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
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
            }
            .onChange(of: alwaysShowLogMeal) { _, _ in save() }
            .onChange(of: beforeHours) { _, _ in save() }
            .onChange(of: afterHours) { _, _ in save() }
            .onChange(of: dashboardMealListCount) { _, _ in save() }
            .onChange(of: mealTimeDisplayMode) { _, _ in save() }
            .onChange(of: unitSystem) { _, _ in save() }

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

        current.unitSystem = unitSystem.rawValue

        try? modelContext.save()
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

    private func hoursText(_ hours: Double) -> String {
        if hours == 0 { return "Off" }
        if hours < 1 {
            return "\(Int(hours * 60)) minutes"
        }
        if hours == 1 { return "1 hour" }
        return String(format: "%.1f hours", hours)
    }
}

#Preview {
    SettingsView()
}
