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

                                        Button("Change eating window") {
                                            isPickingSchedule = true
                                        }
                                        .font(.footnote)

                                        if !shouldShowPrimaryLogMeal {
                                            Button("Log meal") {
                                                isLoggingMeal = true
                                            }
                                            .font(.footnote)
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label("Outside eating window", systemImage: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)

                                        EatingWindowStatusView(schedule: selectedSchedule, lastMeal: lastMeal)

                                        Button("Change eating window") {
                                            isPickingSchedule = true
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)

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
        }
        .appScreen()
        .task {
            await health.refreshIfCacheStale()
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

            if let bf = health.latestBodyFat {
                Text(String(format: "Body fat %.1f%%", bf.percent))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            switch health.permission {
            case .authorized:
                if health.weightsLast7Days.isEmpty {
                    Text("No weight data yet. Add weight in Apple Health, then refresh.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(health.weightsLast7Days) { s in
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
                    .frame(height: 120)
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
