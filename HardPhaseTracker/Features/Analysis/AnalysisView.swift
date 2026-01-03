import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var health = HealthKitViewModel()
    @State private var isShowingSettings = false

    @Query private var settings: [AppSettings]
    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)]) private var mealEntries: [MealLogEntry]

    private var weeklyProteinGoalGrams: Double {
        settings.first?.weeklyProteinGoalGrams ?? 0
    }

    private var weeklyProteinSummaries: [WeeklyProteinSummary] {
        WeeklyProteinAggregationService.summaries(entries: mealEntries, goalGrams: weeklyProteinGoalGrams)
    }

    private var sleepCorrelationRows: [SleepFastingCorrelationRow] {
        SleepFastingCorrelationService.rows(sleepNights: health.sleepLast7Nights, mealEntries: mealEntries)
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
                            LabeledContent("Latest weight", value: String(format: "%.1f kg", w.kilograms))
                        } else {
                            LabeledContent("Latest weight", value: "—")
                        }

                        if let bf = health.latestBodyFat {
                            LabeledContent("Latest body fat", value: String(format: "%.1f%%", bf.percent))
                        } else {
                            LabeledContent("Latest body fat", value: "—")
                        }

                        if !health.weightsLast7Days.isEmpty {
                            NavigationLink("Weight (last 7 days)") {
                                List(health.weightsLast7Days) { s in
                                    LabeledContent(s.date.formatted(date: .abbreviated, time: .omitted), value: String(format: "%.1f kg", s.kilograms))
                                }
                                .navigationTitle("Weight")
                            }
                        }

                        if !health.sleepLast7Nights.isEmpty {
                            NavigationLink("Sleep (last 7 nights)") {
                                List(health.sleepLast7Nights) { n in
                                    LabeledContent(n.date.formatted(date: .abbreviated, time: .omitted), value: formatHours(n.asleepSeconds))
                                }
                                .navigationTitle("Sleep")
                            }
                        }
                    }

                    if let msg = health.errorMessage {
                        Text(msg)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Protein") {
                    if weeklyProteinGoalGrams <= 0 {
                        Text("Set a weekly protein goal in Settings (Dashboard → gear).")
                            .foregroundStyle(.secondary)
                    } else if let current = weeklyProteinSummaries.first {
                        ProgressView(value: current.totalProteinGrams, total: max(1, current.goalProteinGrams)) {
                            Text("This week")
                        } currentValueLabel: {
                            Text("\(Int(current.totalProteinGrams.rounded())) / \(Int(current.goalProteinGrams.rounded())) g")
                        }
                        .accessibilityLabel("Weekly protein progress")
                    }

                    if weeklyProteinSummaries.isEmpty {
                        Text("No logged meals yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(weeklyProteinSummaries) { s in
                            let total = Int(s.totalProteinGrams.rounded())
                            let goal = Int(s.goalProteinGrams.rounded())
                            LabeledContent(weekLabel(s), value: s.goalProteinGrams > 0 ? "\(total) / \(goal) g" : "\(total) g")
                        }
                    }
                }

                Section("Sleep ↔ Fasting") {
                    if health.permission != .authorized {
                        Text("Connect Apple Health to see sleep correlation.")
                            .foregroundStyle(.secondary)
                    } else if sleepCorrelationRows.isEmpty {
                        Text("Insufficient sleep data.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sleepCorrelationRows) { row in
                            let fasting = row.fastingSecondsAtWake.map(formatHours) ?? "—"
                            LabeledContent(
                                row.date.formatted(date: .abbreviated, time: .omitted),
                                value: "Fasting \(fasting) · Sleep \(formatHours(row.asleepSeconds))"
                            )
                        }

                        Text("Fasting is estimated from the last logged meal to ~6am on the sleep day.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                }
            }
            .task {
                // Prefer cached data for fast load; only hit HealthKit when cache is empty/stale.
                await health.refreshIfCacheStale()
            }
        }
        .appScreen()
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .accessibilityIdentifier("tab.analysis")
    }

    private func weekLabel(_ summary: WeeklyProteinSummary) -> String {
        let cal = Calendar(identifier: .iso8601)
        let endInclusive = cal.date(byAdding: .day, value: -1, to: summary.weekEnd) ?? summary.weekEnd
        return "\(summary.weekStart.formatted(date: .abbreviated, time: .omitted)) – \(endInclusive.formatted(date: .abbreviated, time: .omitted))"
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        String(format: "%.1f h", seconds / 3600)
    }
}

#Preview {
    AnalysisView()
}
