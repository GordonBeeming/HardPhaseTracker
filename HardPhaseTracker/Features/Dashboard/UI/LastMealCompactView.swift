import SwiftUI

struct LastMealCompactView: View {
    let lastMeal: MealLogEntry?
    let settings: AppSettings?

    var body: some View {
        Group {
            if let lastMeal {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let elapsed = FastingEngine.elapsed(from: lastMeal.timestamp, to: context.date)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Since last meal")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(formatted(elapsed: elapsed))
                            .font(.headline.weight(.semibold))

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
            }
        }
        .padding(.horizontal)
    }

    private func formatted(elapsed: TimeInterval) -> String {
        DateFormatting.formatDurationShort(seconds: elapsed, maxUnits: 2)
    }
}
