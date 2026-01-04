import SwiftUI

struct FastingTimerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let lastMeal: MealLogEntry?
    let settings: AppSettings?

    var body: some View {
        Group {
            if let lastMeal {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let elapsed = FastingEngine.elapsed(from: lastMeal.timestamp, to: context.date)
                    let phase = FastingEngine.phase(for: elapsed)

                    VStack(spacing: 8) {
                        Text(formatted(elapsed: elapsed))
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .foregroundStyle(phase.color(using: AppTheme.self, scheme: colorScheme))

                        Text("Since last meal")
                            .foregroundStyle(.secondary)

                        Text(
                            DateFormatting.formatMealTime(
                                date: lastMeal.timestamp,
                                capturedTimeZoneIdentifier: lastMeal.timeZoneIdentifier,
                                displayMode: settings?.mealTimeDisplayModeEnum ?? .captured,
                                badgeStyle: .abbrev,
                                offsetStyle: .utc
                            )
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView("No meals logged", systemImage: "timer")
            }
        }
    }

    private func formatted(elapsed: TimeInterval) -> String {
        DateFormatting.formatDurationShort(seconds: elapsed, maxUnits: 2)
    }
}

#Preview {
    FastingTimerView(lastMeal: nil, settings: nil)
}
