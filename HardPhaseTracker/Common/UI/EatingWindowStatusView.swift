import SwiftUI

struct EatingWindowStatusView: View {
    let schedule: EatingWindowSchedule
    let lastMeal: MealLogEntry?

    @State private var now: Date = .now

    var body: some View {
        TimelineView(timelineSchedule) { context in
            let now = context.date

            VStack(alignment: .leading, spacing: 8) {
                Text(schedule.name)
                    .font(.headline)

                Text(EatingWindowEvaluator.windowText(schedule: schedule))
                    .foregroundStyle(.secondary)

                if let current = EatingWindowNavigator.currentWindowRange(schedule: schedule, now: now) {
                    let total = current.end.timeIntervalSince(current.start)
                    let elapsed = now.timeIntervalSince(current.start)
                    let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

                    ProgressView(value: progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)

                    Text("Eating window ends \(durationText(current.end.timeIntervalSince(now)))")
                        .foregroundStyle(.green)
                } else {
                    let nextStart = EatingWindowNavigator.nextWindowStart(schedule: schedule, now: now)
                    let prevEnd = EatingWindowNavigator.previousWindowEnd(schedule: schedule, now: now)

                    let timeToNext = nextStart.map { $0.timeIntervalSince(now) } ?? 0

                    let showCountdown: Bool = {
                        guard let nextStart, let prevEnd else { return true }
                        let gap = nextStart.timeIntervalSince(prevEnd)
                        guard gap > 0 else { return true }
                        let progressed = now.timeIntervalSince(prevEnd) / gap
                        return progressed >= 0.40
                    }()

                    ProgressView(value: progressToNextWindow(now: now))
                        .animation(.easeInOut(duration: 0.3), value: progressToNextWindow(now: now))

                    if showCountdown, timeToNext > 0 {
                        Text("Next eating window in \(durationText(timeToNext))")
                            .foregroundStyle(.secondary)
                    } else if let lastMeal {
                        Text("Last meal \(durationText(now.timeIntervalSince(lastMeal.timestamp))) ago")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Outside eating window")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var timelineSchedule: some TimelineSchedule {
        // If we will ever show seconds, tick every second; otherwise every minute.
        .periodic(from: .now, by: updateIntervalSeconds)
    }

    private var updateIntervalSeconds: TimeInterval {
        // seconds only when < 1 minute until next window OR < 1 minute since last meal
        let now = Date()
        if let current = EatingWindowNavigator.currentWindowRange(schedule: schedule, now: now) {
            let remaining = current.end.timeIntervalSince(now)
            return remaining < 60 ? 1 : 60
        }

        if let nextStart = EatingWindowNavigator.nextWindowStart(schedule: schedule, now: now) {
            let remaining = nextStart.timeIntervalSince(now)
            return remaining < 60 ? 1 : 60
        }

        if let lastMeal {
            let elapsed = now.timeIntervalSince(lastMeal.timestamp)
            return elapsed < 60 ? 1 : 60
        }

        return 60
    }

    private func progressToNextWindow(now: Date) -> Double {
        guard let nextStart = EatingWindowNavigator.nextWindowStart(schedule: schedule, now: now),
              let prevEnd = EatingWindowNavigator.previousWindowEnd(schedule: schedule, now: now) else {
            return 0
        }

        let gap = nextStart.timeIntervalSince(prevEnd)
        guard gap > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(prevEnd)
        return max(0, min(1, elapsed / gap))
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        DateFormatting.formatDurationShort(seconds: seconds, maxUnits: 2)
    }
}
