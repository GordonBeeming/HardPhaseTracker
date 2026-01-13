import SwiftUI

struct EatingWindowStatusView: View {
    let schedule: EatingWindowSchedule
    let lastMeal: MealLogEntry?

    @Environment(\.colorScheme) private var colorScheme
    @State private var now: Date = .now
    @State private var showingPhaseInfo = false

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

                    // Calculate fasting phase information
                    let hoursSinceLastMeal: Double? = {
                        guard let lastMeal else { return nil }
                        return now.timeIntervalSince(lastMeal.timestamp) / 3600
                    }()
                    
                    let currentPhase = hoursSinceLastMeal.flatMap { FastingPhaseInfo.currentPhase(hoursSinceLastMeal: $0) }

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
                    
                    // Show fasting phase if we have a last meal
                    if let currentPhase, let hoursSinceLastMeal {
                        HStack(spacing: 6) {
                            Text(currentPhase.emoji)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(currentPhase.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Button {
                                        showingPhaseInfo = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Text(phaseProgressText(phase: currentPhase, hoursSinceLastMeal: hoursSinceLastMeal))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        
                        // Show progress bar for phases with defined durations
                        let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: hoursSinceLastMeal)
                        if progress > 0 {
                            ProgressView(value: progress)
                                .tint(currentPhase.color(for: colorScheme))
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhaseInfo) {
            FastingPhaseInfoView()
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
    
    private func phaseProgressText(phase: FastingPhaseInfo, hoursSinceLastMeal: Double) -> String {
        let hours = Int(hoursSinceLastMeal)
        let phaseNumber = FastingPhaseInfo.phases.firstIndex(where: { $0.name == phase.name }).map { $0 + 1 } ?? 0
        
        // Extract just the hour range (e.g., "48-72h" from "Hours 48-72")
        let range = phase.hourRange
            .replacingOccurrences(of: "Hours ", with: "")
            .replacingOccurrences(of: "–", with: "-")
        
        // Handle sub-stages (e.g., "Hours 72-96 (Sub-Stage A)")
        let cleanRange: String
        if range.contains("(") {
            // Extract "48-72h" from "72-96 (Sub-Stage A)"
            let parts = range.components(separatedBy: " (")
            cleanRange = parts[0] + "h"
        } else {
            cleanRange = range + (range.contains("h") ? "" : "h")
        }
        
        return "Stage \(phaseNumber) • \(hours)h fasting (\(cleanRange))"
    }
}
