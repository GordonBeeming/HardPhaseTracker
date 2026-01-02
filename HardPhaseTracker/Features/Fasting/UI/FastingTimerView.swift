import SwiftUI

struct FastingTimerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let lastMeal: MealLogEntry?

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

                        Text(DateFormatting.format(date: lastMeal.timestamp, timeZoneIdentifier: lastMeal.timeZoneIdentifier))
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
        let totalMinutes = Int(elapsed / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm", days, hours, minutes)
        }
        return String(format: "%02dh %02dm", hours, minutes)
    }
}

#Preview {
    FastingTimerView(lastMeal: nil)
}
