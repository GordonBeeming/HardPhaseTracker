import SwiftUI

struct AnalysisView: View {
    @StateObject private var health = HealthKitViewModel()

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
                                    let hours = n.asleepSeconds / 3600
                                    LabeledContent(n.date.formatted(date: .abbreviated, time: .omitted), value: String(format: "%.1f h", hours))
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

                Section {
                    ContentUnavailableView(
                        "More insights coming soon",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Charts and analytics will arrive in a future milestone.")
                    )
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Prefer cached data for fast load; only hit HealthKit when cache is empty/stale.
                await health.refreshIfCacheStale()
            }
        }
        .appScreen()
        .accessibilityIdentifier("tab.analysis")
    }
}

#Preview {
    AnalysisView()
}
