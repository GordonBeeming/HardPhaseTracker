import SwiftUI

struct SleepDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let sleepNights: [SleepNight]
    @Binding var selectedDaysRange: Int
    
    private var filteredSleepNights: [SleepNight] {
        guard selectedDaysRange > 0 else { return sleepNights }
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDaysRange, to: Date()) ?? Date()
        return sleepNights.filter { $0.date >= cutoff }
    }
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        String(format: "%.1f h", seconds / 3600)
    }
    
    var body: some View {
        List {
            Section {
                Picker("Show data for", selection: $selectedDaysRange) {
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                    Text("All data").tag(0)
                }
                .pickerStyle(.menu)
            }
            
            Section {
                ForEach(filteredSleepNights.prefix(selectedDaysRange > 0 ? selectedDaysRange : filteredSleepNights.count)) { night in
                    LabeledContent(
                        night.date.formatted(date: .abbreviated, time: .omitted),
                        value: formatHours(night.asleepSeconds)
                    )
                }
            }
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
}
