import SwiftUI

struct LastMealCompactView: View {
    let lastMeal: MealLogEntry?
    let settings: AppSettings?

    var body: some View {
        Group {
            if let lastMeal {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let elapsed = FastingEngine.elapsed(from: lastMeal.timestamp, to: context.date)

                    Text("\(formatted(elapsed: elapsed)) since last meal")
                        .font(.headline)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatted(elapsed: TimeInterval) -> String {
        DateFormatting.formatDurationShort(seconds: elapsed, maxUnits: 2)
    }
}
