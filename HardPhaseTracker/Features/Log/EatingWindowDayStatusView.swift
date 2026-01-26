import SwiftUI

struct EatingWindowDayStatusView: View {
    let date: Date
    let schedule: EatingWindowSchedule?
    let override: EatingWindowOverride?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        // Only show for today and future dates
        if !isPastDate {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let subtitle = statusSubtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPastDate: Bool {
        calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
    }
    
    private var isEatingDay: Bool {
        if let override = override {
            return override.overrideTypeEnum == .eating
        }
        
        guard let schedule = schedule else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return schedule.isActive(on: weekday)
    }
    
    private var hasOverride: Bool {
        override != nil
    }
    
    private var statusIcon: String {
        if let override = override {
            return override.overrideTypeEnum == .skip ? "xmark.circle.fill" : "star.fill"
        }
        return isEatingDay ? "fork.knife.circle.fill" : "moon.circle.fill"
    }
    
    private var statusColor: Color {
        if let override = override {
            return override.overrideTypeEnum == .skip ? .red : .orange
        }
        return isEatingDay ? .green : .blue
    }
    
    private var statusTitle: String {
        if let override = override {
            if override.overrideTypeEnum == .skip {
                return "Skipped eating day"
            } else {
                return override.startMinutes != nil ? "Custom eating window" : "Added eating day"
            }
        }
        return isEatingDay ? "Eating day" : "Fasting day"
    }
    
    private var statusSubtitle: String? {
        guard isEatingDay, let schedule = schedule else { return nil }
        
        let startMin = override?.startMinutes ?? schedule.startMinutes
        let endMin = override?.endMinutes ?? schedule.endMinutes
        
        return "\(formatTime(startMin)) – \(formatTime(endMin))"
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}
