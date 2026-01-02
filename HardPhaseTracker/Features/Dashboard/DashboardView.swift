import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MealLogEntry.timestamp, order: .reverse)])
    private var mealLogs: [MealLogEntry]

    @Query private var settings: [AppSettings]

    @State private var isLoggingMeal = false
    @State private var isPickingSchedule = false

    private var lastMeal: MealLogEntry? { mealLogs.first }
    private var selectedSchedule: EatingWindowSchedule? { settings.first?.selectedSchedule }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                FastingTimerView(lastMeal: lastMeal)

                VStack(spacing: 10) {
                    if let selectedSchedule {
                        let inWindow = EatingWindowEvaluator.isNowInWindow(schedule: selectedSchedule)
                        VStack(spacing: 6) {
                            Text(selectedSchedule.name)
                                .font(.headline)
                            Text(EatingWindowEvaluator.windowText(schedule: selectedSchedule))
                                .foregroundStyle(.secondary)
                            Text(inWindow ? "In eating window" : "Outside eating window")
                                .foregroundStyle(inWindow ? .green : .secondary)
                        }
                    } else {
                        Text("No eating window schedule set")
                            .foregroundStyle(.secondary)
                    }

                    Button("Change eating window") {
                        isPickingSchedule = true
                    }
                    .font(.footnote)
                }

                Button("Log Meal") {
                    isLoggingMeal = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .accessibilityIdentifier("dashboard.logMeal")

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Dashboard")
        }
        .appScreen()
        .sheet(isPresented: $isLoggingMeal) {
            MealQuickLogView()
        }
        .sheet(isPresented: $isPickingSchedule) {
            SchedulePickerView()
        }
        .accessibilityIdentifier("tab.dashboard")
    }
}

#Preview {
    DashboardView()
}
