import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var mealLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]

    @State private var isLoggingMeal = false
    @State private var isPickingSchedule = false
    @State private var isShowingSettings = false

    @StateObject private var health = HealthKitViewModel()

    private var lastMeal: MealLogEntry? { mealLogs.first }
    private var selectedSchedule: EatingWindowSchedule? { settings.first?.selectedSchedule }

    private var appSettings: AppSettings? { settings.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if shouldShowPrimaryLogMeal {
                        Button("Log Meal") {
                            isLoggingMeal = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        .accessibilityIdentifier("dashboard.logMeal")
                    }

                    if DashboardOnboardingPolicy.shouldShowOnboarding(selectedSchedule: selectedSchedule) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Get started")
                                .font(.headline)

                            Text("Select your eating window so we can show your fasting progress and whether you’re currently inside or outside your window.")
                                .foregroundStyle(.secondary)

                            Button("Select your eating window") {
                                isPickingSchedule = true
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.cardBackground(colorScheme))
                        )
                        .padding(.horizontal)
                    } else if let selectedSchedule {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            let inWindow = EatingWindowEvaluator.isNowInWindow(schedule: selectedSchedule, now: context.date)

                            VStack(spacing: 12) {
                                ElectrolyteChecklistView(date: context.date, settings: appSettings)
                                    .padding(.horizontal)

                                if inWindow {
                                    VStack(spacing: 10) {
                                        EatingWindowStatusView(schedule: selectedSchedule, lastMeal: lastMeal)

                                        if !shouldShowPrimaryLogMeal {
                                            Button("Log meal") {
                                                isLoggingMeal = true
                                            }
                                            .font(.footnote)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(AppTheme.cardBackground(colorScheme))
                                    )
                                    .padding(.horizontal)
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label("Outside eating window", systemImage: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)

                                        EatingWindowStatusView(schedule: selectedSchedule, lastMeal: lastMeal)

                                        if !shouldShowPrimaryLogMeal {
                                            Button("Log meal anyway") {
                                                isLoggingMeal = true
                                            }
                                            .font(.footnote)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.orange.opacity(0.12))
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }


                    DashboardWeightTrendCardView(
                        health: health,
                        unitSystem: appSettings?.unitSystemEnum ?? .metric,
                        weightGoalKg: appSettings?.weightGoalKg,
                        onOpenSettings: { isShowingSettings = true }
                    )
                    .padding(.horizontal)

                    if (appSettings?.dashboardMealListCount ?? 10) > 0 {
                        let count = appSettings?.dashboardMealListCount ?? 10
                        let recent = Array(mealLogs.prefix(count))
                        if !recent.isEmpty {
                            DashboardMealLogSummaryView(entries: recent, settings: appSettings)
                        }
                    }

                }
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background(colorScheme))
            .safeAreaPadding(.top, 8)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")

                }
            }
            .refreshable {
                let maxDays = appSettings?.healthDataMaxPullDays ?? 90
                let startDate = appSettings?.healthMonitoringStartDate
                await health.incrementalRefresh(maxDays: maxDays, startDate: startDate, minDisplayTime: 1.0)
            }
        }
        .appScreen()
        .task {
            let maxDays = appSettings?.healthDataMaxPullDays ?? 90
            let startDate = appSettings?.healthMonitoringStartDate
            await health.refreshIfTodayWeightMissing(maxDays: maxDays, startDate: startDate)
        }
        .sheet(isPresented: $isLoggingMeal) {
            MealQuickLogView {
                isLoggingMeal = false
            }
        }
        .sheet(isPresented: $isPickingSchedule) {
            SchedulePickerView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .accessibilityIdentifier("tab.dashboard")
    }

    private var shouldShowPrimaryLogMeal: Bool {
        LogMealVisibilityPolicy.shouldShowPrimary(
            alwaysShow: appSettings?.alwaysShowLogMealButton ?? false,
            showBeforeHours: appSettings?.logMealShowBeforeHours ?? 0.5,
            showAfterHours: appSettings?.logMealShowAfterHours ?? 2.5,
            schedule: selectedSchedule
        )
    }
}

private struct DashboardWeightTrendCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var health: HealthKitViewModel
    let unitSystem: UnitSystem
    let weightGoalKg: Double?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weight")
                    .font(.headline)

                Spacer()

                if let w = health.latestWeight {
                    Text(formatWeight(kilograms: w.kilograms))
                        .font(.headline)
                }
            }

            // Show weight loss info if we have first and latest weight
            if let first = health.firstWeight, let latest = health.latestWeight {
                let lostKg = first.kilograms - latest.kilograms
                if lostKg > 0 {
                    let duration = formatDuration(from: first.date, to: latest.date)
                    Text("Lost \(formatWeight(kilograms: lostKg)) in \(duration)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let bf = health.latestBodyFat {
                Text(String(format: "Body fat %.1f%%", bf.percent))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            switch health.permission {
            case .authorized:
                if health.weightsLast14Days.isEmpty {
                    Text("No weight data yet. Add weight in Apple Health, then refresh.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    let yBounds = calculateYAxisBounds()
                    Chart {
                        ForEach(health.weightsLast14Days, id: \.date) { s in
                            LineMark(
                                x: .value("Date", s.date),
                                y: .value("Weight", displayValue(kilograms: s.kilograms))
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", s.date),
                                y: .value("Weight", displayValue(kilograms: s.kilograms))
                            )
                        }
                        
                        // Show goal line if goal is set and visible in chart range
                        if let goalKg = weightGoalKg {
                            let goalDisplay = displayValue(kilograms: goalKg)
                            if goalDisplay >= yBounds.min && goalDisplay <= yBounds.max {
                                RuleMark(y: .value("Goal", goalDisplay))
                                    .foregroundStyle(.red.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }
                        }
                    }
                    .chartYScale(domain: yBounds.min...yBounds.max)
                    .frame(height: 120)

                    if weightGoalKg == nil {
                        Text("Set a weight goal in Settings to optimize chart view")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

            case .notAvailable:
                Text("Apple Health isn’t available on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case .notDetermined, .denied:
                Text("Connect Apple Health to show your weight trend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Open Settings") {
                    onOpenSettings()
                }
                .font(.footnote)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground(colorScheme))
        )
        .accessibilityIdentifier("dashboard.weightTrend")
    }

    private func calculateYAxisBounds() -> (min: Double, max: Double) {
        let weights = health.weightsLast14Days.map { displayValue(kilograms: $0.kilograms) }
        guard let dataMin = weights.min(), let dataMax = weights.max() else {
            return (min: 0, max: 100)
        }

        // Calculate lower bound: current weight - 2, rounded down to nearest 5
        let currentMinus2 = dataMax - 2
        let lowerBound = floor(currentMinus2 / 5) * 5
        
        // Use the actual data minimum if it's lower than our calculated bound
        let finalLowerBound = min(lowerBound, dataMin)

        // Add small padding for visual spacing
        let padding = 2.0
        let finalMin = max(0, finalLowerBound - padding)
        let finalMax = dataMax + padding

        return (min: finalMin, max: finalMax)
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0

        if days <= 21 {
            // Show days for first 3 weeks
            return days == 1 ? "1 day" : "\(days) days"
        } else if days < 84 {
            // Show weeks from 3 weeks to 12 weeks (~3 months)
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "1 month" : "\(months) months"
        } else {
            let years = days / 365
            let remainingMonths = (days % 365) / 30
            if remainingMonths == 0 {
                return years == 1 ? "1 year" : "\(years) years"
            } else {
                return "\(years)y \(remainingMonths)m"
            }
        }
    }

    private func displayValue(kilograms: Double) -> Double {
        switch unitSystem {
        case .metric:
            return kilograms
        case .imperial:
            return kilograms * 2.20462262
        }
    }

    private func formatWeight(kilograms: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", kilograms)
        case .imperial:
            return String(format: "%.1f lb", kilograms * 2.20462262)
        }
    }
}

#Preview {
    DashboardView()
}
