import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var mealLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]

    @State private var isLoggingMeal = false
    @State private var isPickingSchedule = false
    @State private var isShowingSettings = false

    private var lastMeal: MealLogEntry? { mealLogs.first }
    private var selectedSchedule: EatingWindowSchedule? { settings.first?.selectedSchedule }

    private var appSettings: AppSettings? { settings.first }

    var body: some View {
        NavigationStack {
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
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .padding(.horizontal)
                } else if let selectedSchedule {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let inWindow = EatingWindowEvaluator.isNowInWindow(schedule: selectedSchedule, now: context.date)

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


                if (appSettings?.dashboardMealListCount ?? 10) > 0 {
                    let count = appSettings?.dashboardMealListCount ?? 10
                    let recent = Array(mealLogs.prefix(count))
                    if !recent.isEmpty {
                        DashboardMealLogSummaryView(entries: recent, settings: appSettings)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }

                }
            }
        }
        .appScreen()
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

#Preview {
    DashboardView()
}
