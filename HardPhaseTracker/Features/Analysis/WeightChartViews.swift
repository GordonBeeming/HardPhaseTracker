import SwiftUI
import Charts

struct WeightByWeekView: View {
    @Environment(\.colorScheme) private var colorScheme
    let weeklyChanges: [(weekStart: Date, change: Double)]
    
    var body: some View {
        List {
            Section {
                if weeklyChanges.isEmpty {
                    Text("Not enough weight data to show weekly trends.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(weeklyChanges, id: \.weekStart) { item in
                        BarMark(
                            x: .value("Week", item.weekStart, unit: .weekOfYear),
                            y: .value("Change", -item.change)
                        )
                        .foregroundStyle(item.change < 0 ? .green : .orange)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 250)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Weekly Weight Change")
            } footer: {
                Text("Shows weight change per week. Green bars above = weight loss, Orange bars below = weight gain.")
            }
            
            Section("Details") {
                ForEach(weeklyChanges.reversed(), id: \.weekStart) { item in
                    HStack {
                        Text(formatWeek(item.weekStart))
                        Spacer()
                        Text(formatChange(item.change))
                            .foregroundStyle(item.change < 0 ? .green : .orange)
                    }
                }
            }
        }
        .navigationTitle("Weight Change by Week")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
    
    private func formatWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: date))"
    }
    
    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.1f kg", sign, change)
    }
}

struct WeightByDayOfWeekView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dayData: [(dayOfWeek: Int, dayName: String, avgChange: Double)]
    
    var body: some View {
        List {
            Section {
                if dayData.isEmpty {
                    Text("Not enough weight data to show day-of-week patterns.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(dayData, id: \.dayOfWeek) { item in
                        BarMark(
                            x: .value("Day", item.dayName),
                            y: .value("Avg Change", -item.avgChange)
                        )
                        .foregroundStyle(item.avgChange < 0 ? .green : .orange)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 250)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Average Weight Change by Day")
            } footer: {
                Text("Shows average weight change for each day of the week. Green bars above = typical weight loss, Orange bars below = typical weight gain.")
            }
            
            Section("Details") {
                ForEach(dayData, id: \.dayOfWeek) { item in
                    HStack {
                        Text(item.dayName)
                        Spacer()
                        Text(formatChange(item.avgChange))
                            .foregroundStyle(item.avgChange < 0 ? .green : .orange)
                    }
                }
            }
        }
        .navigationTitle("Weight Change by Day")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
    
    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.2f kg", sign, change)
    }
}
