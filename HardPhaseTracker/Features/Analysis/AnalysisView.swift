import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var health = HealthKitViewModel.sharedHealth
    @State private var isShowingSettings = false

    @Query private var settings: [AppSettings]
    @Query private var mealEntries: [MealLogEntry]

    init() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -180, to: .now) ?? .distantPast
        _mealEntries = Query(
            filter: #Predicate<MealLogEntry> { $0.timestamp >= cutoff },
            sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)]
        )
    }

    private var appSettings: AppSettings? {
        settings.first
    }
    
    private var filteredWeights: [WeightSample] {
        let daysRange = appSettings?.weightChartDaysRange ?? 14 // Default to 14 days
        guard daysRange > 0 else {
            return health.allWeights // All data if 0 or nil
        }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysRange, to: Date()) ?? Date()
        return health.allWeights.filter { $0.date >= cutoff }
    }
    
    private var filteredSleepNights: [SleepNight] {
        let daysRange = appSettings?.sleepChartDaysRange ?? 14 // Default to 14 days
        guard daysRange > 0 else {
            return health.allSleepNights // All data if 0 or nil
        }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysRange, to: Date()) ?? Date()
        return health.allSleepNights.filter { $0.date >= cutoff }
    }
    
    private var weeklyWeightChanges: [(weekStart: Date, change: Double)] {
        let startDay = appSettings?.weekStartDayEnum ?? .monday
        return WeightAnalysisService.weeklyChanges(weights: filteredWeights, weekStartDay: startDay)
    }
    
    private var averageWeightChangeByDayOfWeek: [(dayOfWeek: Int, dayName: String, avgChange: Double)] {
        let startDay = appSettings?.weekStartDayEnum ?? .monday
        return WeightAnalysisService.averageChangeByDayOfWeek(weights: filteredWeights, weekStartDay: startDay)
    }
    
    private var weightDelta: Double? {
        guard let latest = health.latestWeight else { return nil }
        
        // Find the second most recent weight (previous weight before latest)
        let previousWeight = health.allWeights
            .filter { $0.date < latest.date }
            .last // Get the most recent one before latest
        
        guard let previous = previousWeight else { return nil }
        
        return latest.kilograms - previous.kilograms
    }
    
    private func formatWeightWithDelta(_ kilograms: Double, delta: Double?) -> String {
        let weightStr = String(format: "%.1f kg", kilograms)
        guard let delta = delta else { return weightStr }
        
        let sign = delta >= 0 ? "+" : ""
        let deltaStr = String(format: "(%@%.1f)", sign, delta)
        return "\(weightStr) \(deltaStr)"
    }
    
    private func deltaColor(_ delta: Double?) -> Color {
        guard let delta = delta else { return .primary }
        return delta < 0 ? .green : .orange
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Apple Health") {
                    switch health.permission {
                    case .notAvailable:
                        Text("Health data isn’t available on this device.")
                            .foregroundStyle(.secondary)

                    case .notDetermined:
                        Text("Connect Apple Health to view weight and sleep (read-only).")
                            .foregroundStyle(.secondary)

                        Button("Connect to Apple Health") {
                            Task { await health.requestAccess() }
                        }

                    case .denied:
                        Text("Access was denied. You can enable it in Settings → Health → Data Access & Devices.")
                            .foregroundStyle(.secondary)

                    case .authorized:
                        Text("Manage Apple Health connection in Settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let w = health.latestWeight {
                            NavigationLink {
                                WeightDetailView(
                                    health: health,
                                    selectedDaysRange: Binding(
                                        get: { appSettings?.weightChartDaysRange ?? 14 },
                                        set: { newValue in
                                            if let settings = appSettings {
                                                settings.weightChartDaysRange = newValue == 0 ? nil : newValue
                                            }
                                        }
                                    )
                                )
                            } label: {
                                LabeledContent("Latest weight") {
                                    HStack(spacing: 4) {
                                        Text(String(format: "%.1f kg", w.kilograms))
                                            .foregroundStyle(.primary)
                                        if let delta = weightDelta {
                                            Text(String(format: "(%@%.1f)", delta >= 0 ? "+" : "", delta))
                                                .foregroundStyle(delta < 0 ? .green : .orange)
                                        }
                                    }
                                }
                            }
                        } else {
                            LabeledContent("Latest weight", value: "—")
                        }

                        if let bf = health.latestBodyFat {
                            LabeledContent("Latest body fat", value: String(format: "%.1f%%", bf.percent))
                        } else {
                            LabeledContent("Latest body fat", value: "—")
                        }
                        
                        if let sleep = health.latestSleep {
                            NavigationLink {
                                SleepDetailView(
                                    sleepNights: health.allSleepNights,
                                    selectedDaysRange: Binding(
                                        get: { appSettings?.sleepChartDaysRange ?? 14 },
                                        set: { newValue in
                                            if let settings = appSettings {
                                                settings.sleepChartDaysRange = newValue == 0 ? nil : newValue
                                            }
                                        }
                                    )
                                )
                            } label: {
                                LabeledContent("Latest sleep", value: formatHours(sleep.asleepSeconds))
                            }
                        } else {
                            LabeledContent("Latest sleep", value: "—")
                        }
                    }

                    if let msg = health.errorMessage {
                        Text(msg)
                            .foregroundStyle(.secondary)
                    }
                }

                if (health.permission == .authorized || !health.allWeights.isEmpty) && !health.allWeights.isEmpty {
                    Section("Weight Analysis") {
                        NavigationLink("Weight Change by Week") {
                            WeightByWeekView(
                                weeklyChanges: weeklyWeightChanges,
                                allWeights: filteredWeights,
                                weekStartDay: appSettings?.weekStartDayEnum ?? .monday
                            )
                        }
                        
                        NavigationLink("Weight Change by Day of Week") {
                            WeightByDayOfWeekView(dayData: averageWeightChangeByDayOfWeek)
                        }
                    }
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background(colorScheme))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .task {
                // Prefer cached data for fast load; only hit HealthKit when cache is empty/stale.
                let maxDays = appSettings?.healthDataMaxPullDays ?? 90
                let startDate = appSettings?.healthMonitoringStartDate
                await health.refreshIfCacheStale(maxDays: maxDays, startDate: startDate)
            }
        }
        .appScreen()
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .accessibilityIdentifier("tab.analysis")
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        String(format: "%.1f h", seconds / 3600)
    }
}

#Preview {
    AnalysisView()
}
