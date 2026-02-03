import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var mealLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]
    
    @Query private var allOverrides: [EatingWindowOverride]

    @State private var isLoggingMeal = false
    @State private var isPickingSchedule = false
    @State private var isShowingSettings = false

    @ObservedObject private var health = HealthKitViewModel.sharedHealth

    private var lastMeal: MealLogEntry? { mealLogs.first }
    private var selectedSchedule: EatingWindowSchedule? { settings.first?.selectedSchedule }

    private var appSettings: AppSettings? { settings.first }
    
    private var todayOverride: EatingWindowOverride? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return allOverrides.first { cal.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if shouldShowPrimaryLogMeal(at: Date(), override: todayOverride) {
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
                            let inWindow = EatingWindowEvaluator.isNowInWindow(schedule: selectedSchedule, now: context.date, override: todayOverride)
                            let showPrimary = shouldShowPrimaryLogMeal(at: context.date, override: todayOverride)

                            VStack(spacing: 12) {
                                ElectrolyteChecklistView(date: context.date, settings: appSettings)
                                    .padding(.horizontal)

                                if inWindow {
                                    VStack(spacing: 10) {
                                        EatingWindowStatusView(schedule: selectedSchedule, lastMeal: lastMeal, override: todayOverride)

                                        if !showPrimary {
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

                                        EatingWindowStatusView(schedule: selectedSchedule, lastMeal: lastMeal, override: todayOverride)

                                        if !showPrimary {
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

    private func shouldShowPrimaryLogMeal(at date: Date, override: EatingWindowOverride?) -> Bool {
        LogMealVisibilityPolicy.shouldShowPrimary(
            alwaysShow: appSettings?.alwaysShowLogMealButton ?? false,
            showBeforeHours: appSettings?.logMealShowBeforeHours ?? 0.5,
            showAfterHours: appSettings?.logMealShowAfterHours ?? 2.5,
            schedule: selectedSchedule,
            override: override,
            overrides: allOverrides,
            now: date
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
                    HStack(spacing: 4) {
                        Text(formatWeight(kilograms: w.kilograms))
                            .font(.headline)
                        
                        // Show 7-day delta in brackets with color if available
                        if let delta7Days = calculate7DayDelta() {
                            Text(formatDelta(delta7Days))
                                .font(.headline)
                                .foregroundStyle(delta7Days < 0 ? .green : .orange)
                        }
                    }
                }
            }

            // Show weight loss info if we have first and latest weight
            if let first = health.firstWeight, let latest = health.latestWeight {
                let lostKg = first.kilograms - latest.kilograms
                if lostKg > 0 {
                    let duration = formatDuration(from: first.date, to: latest.date)
                    let bodyFatText = health.latestBodyFat.map { String(format: " • Body fat %.1f%%", $0.percent) } ?? ""
                    Text("Lost \(formatWeight(kilograms: lostKg)) in \(duration)\(bodyFatText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let bf = health.latestBodyFat {
                // Show body fat alone if no weight loss info
                Text(String(format: "Body fat %.1f%%", bf.percent))
                    .font(.subheadline)
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
                    let xDomain = calculateXAxisDomain()
                    
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
                    .chartXScale(domain: xDomain)
                    .chartYScale(domain: yBounds.min...yBounds.max)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 120)

                    if weightGoalKg == nil {
                        Text("Set a weight goal in Settings to optimize chart view")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

            case .notAvailable:
                Text("Apple Health isn't available on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case .notDetermined, .denied:
                // Show chart with cached/imported data if available
                if !health.weightsLast14Days.isEmpty {
                    let yBounds = calculateYAxisBounds()
                    let xDomain = calculateXAxisDomain()
                    
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
                    .chartXScale(domain: xDomain)
                    .chartYScale(domain: yBounds.min...yBounds.max)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 120)
                    
                    Text("Using imported health data. Connect to Apple Health to sync live data.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Connect to Apple Health to view weight trends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground(colorScheme))
        )
        .accessibilityIdentifier("dashboard.weightTrend")
    }
    
    private func calculateXAxisDomain() -> ClosedRange<Date> {
        // Always show the last 14 days, even if there's no data for some days
        let now = Date()
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
        return fourteenDaysAgo...now
    }
    
    private func xAxisValues() -> [Date] {
        let weights = health.weightsLast14Days
        guard !weights.isEmpty else { return [] }
        
        var dates: [Date] = []
        
        // First date (start of range)
        if let first = weights.first {
            dates.append(first.date)
        }
        
        // Middle date (approximately 7 days ago from last weight)
        if let last = weights.last {
            let sevenDaysBeforeLast = Calendar.current.date(byAdding: .day, value: -7, to: last.date) ?? last.date
            dates.append(sevenDaysBeforeLast)
        }
        
        // Last date (most recent weight)
        if let last = weights.last {
            dates.append(last.date)
        }
        
        return dates
    }
    
    private func calculateYAxisBounds() -> (min: Double, max: Double) {
        let weights = health.weightsLast14Days.map { displayValue(kilograms: $0.kilograms) }
        guard let dataMin = weights.min(), let dataMax = weights.max() else {
            return (min: 0, max: 100)
        }

        // Calculate lower bound: round DOWN the minimum value to nearest 5
        // This ensures the lowest data point is always visible
        // e.g., 166.2 → 165; 163.8 → 160
        let lowerBound = floor(dataMin / 5) * 5
        
        // Calculate upper bound: round UP the maximum value to nearest 5
        // e.g., 177.69 → 180; 175.0 → 175
        let upperBound = ceil(dataMax / 5) * 5

        // Add 2 units of padding below minimum for better visibility
        let finalMin = max(0, lowerBound - 2)
        let finalMax = upperBound

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
    
    private func calculate7DayDelta() -> Double? {
        guard let latest = health.latestWeight else { return nil }
        
        // Find the second most recent weight (previous weight before latest)
        let previousWeight = health.allWeights
            .filter { $0.date < latest.date }
            .last // Get the most recent one before latest
        
        guard let previous = previousWeight else { return nil }
        
        return latest.kilograms - previous.kilograms
    }
    
    private func formatDelta(_ deltaKg: Double) -> String {
        let sign = deltaKg >= 0 ? "+" : ""
        switch unitSystem {
        case .metric:
            return String(format: "(%@%.1f)", sign, deltaKg)
        case .imperial:
            return String(format: "(%@%.1f)", sign, deltaKg * 2.20462262)
        }
    }
}

#Preview {
    DashboardView()
}
