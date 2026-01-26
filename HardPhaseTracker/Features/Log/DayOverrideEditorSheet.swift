import SwiftUI
import SwiftData

struct DayOverrideEditorSheet: View {
    let date: Date
    let schedule: EatingWindowSchedule?
    let existingOverride: EatingWindowOverride?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAction: ActionType = .none
    @State private var useCustomTimes: Bool = false
    @State private var startMinutes: Int = 720  // 12:00 PM
    @State private var endMinutes: Int = 1200   // 8:00 PM
    
    private let calendar = Calendar.current
    
    enum ActionType: String {
        case none
        case makeEating
        case skip
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Status") {
                    Text(currentStatusText)
                        .foregroundStyle(.secondary)
                }
                
                Section("Options") {
                    // Make eating day button
                    Button {
                        selectedAction = .makeEating
                    } label: {
                        HStack {
                            Label("Make this an eating day", systemImage: "fork.knife")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedAction == .makeEating {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    // Skip eating day button
                    if isCurrentlyScheduledEatingDay {
                        Button {
                            selectedAction = .skip
                        } label: {
                            HStack {
                                Label("Skip this eating day", systemImage: "xmark")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedAction == .skip {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    
                    // Reset to schedule button (only if override exists)
                    if existingOverride != nil {
                        Button {
                            selectedAction = .none
                        } label: {
                            HStack {
                                Label("Reset to schedule default", systemImage: "arrow.counterclockwise")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedAction == .none {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Time customization (only for eating days)
                if selectedAction == .makeEating {
                    Section("Eating Window Times") {
                        Toggle("Customize times", isOn: $useCustomTimes)
                        
                        if useCustomTimes {
                            HStack {
                                Text("Start")
                                Spacer()
                                MinutesPicker(minutes: $startMinutes)
                            }
                            
                            HStack {
                                Text("End")
                                Spacer()
                                MinutesPicker(minutes: $endMinutes)
                            }
                        } else {
                            Text("Will use schedule default: \(scheduleTimesText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                initializeState()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private var isCurrentlyScheduledEatingDay: Bool {
        guard let schedule = schedule else { return false }
        
        if let override = existingOverride {
            return override.overrideTypeEnum == .eating
        }
        
        let weekday = calendar.component(.weekday, from: date)
        return schedule.isActive(on: weekday)
    }
    
    private var currentStatusText: String {
        if let override = existingOverride {
            if override.overrideTypeEnum == .skip {
                return "This day is currently marked as skipped"
            } else {
                if override.startMinutes != nil {
                    return "This day has a custom eating window"
                } else {
                    return "This day is set as an eating day"
                }
            }
        }
        
        if isCurrentlyScheduledEatingDay {
            return "This is a scheduled eating day"
        } else {
            return "This is a fasting day"
        }
    }
    
    private var scheduleTimesText: String {
        guard let schedule = schedule else { return "No schedule" }
        return "\(formatTime(schedule.startMinutes)) – \(formatTime(schedule.endMinutes))"
    }
    
    // MARK: - Actions
    
    private func initializeState() {
        guard let schedule = schedule else { return }
        
        // Initialize time defaults from schedule
        startMinutes = schedule.startMinutes
        endMinutes = schedule.endMinutes
        
        // Initialize from existing override
        if let override = existingOverride {
            if override.overrideTypeEnum == .skip {
                selectedAction = .skip
            } else {
                selectedAction = .makeEating
                if let start = override.startMinutes, let end = override.endMinutes {
                    useCustomTimes = true
                    startMinutes = start
                    endMinutes = end
                }
            }
        } else {
            // No existing override - start with no action selected
            selectedAction = .none
        }
    }
    
    private func saveChanges() {
        if selectedAction == .none && existingOverride != nil {
            // Delete existing override
            EatingWindowOverrideService.deleteOverride(existingOverride!, modelContext: modelContext)
        } else if selectedAction == .makeEating {
            // Create/update eating day override
            let start = useCustomTimes ? startMinutes : nil
            let end = useCustomTimes ? endMinutes : nil
            EatingWindowOverrideService.createOrUpdateOverride(
                date: date,
                type: .eating,
                schedule: schedule,
                startMinutes: start,
                endMinutes: end,
                modelContext: modelContext
            )
        } else if selectedAction == .skip {
            // Create/update skip override
            EatingWindowOverrideService.createOrUpdateOverride(
                date: date,
                type: .skip,
                schedule: schedule,
                startMinutes: nil,
                endMinutes: nil,
                modelContext: modelContext
            )
        }
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

// MARK: - Minutes Picker Component

struct MinutesPicker: View {
    @Binding var minutes: Int
    
    var body: some View {
        HStack(spacing: 4) {
            // Hour picker
            Picker("Hour", selection: Binding(
                get: { minutes / 60 },
                set: { minutes = $0 * 60 + (minutes % 60) }
            )) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 120)
            .clipped()
            
            Text(":")
            
            // Minute picker
            Picker("Minute", selection: Binding(
                get: { minutes % 60 },
                set: { minutes = (minutes / 60) * 60 + $0 }
            )) {
                ForEach(0..<60, id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 120)
            .clipped()
        }
    }
}
