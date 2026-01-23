import SwiftUI
import SwiftData
import Charts

struct WeightByWeekView: View {
    @Environment(\.colorScheme) private var colorScheme
    let weeklyChanges: [(weekStart: Date, change: Double)]
    let allWeights: [WeightSample]
    let weekStartDay: Weekday
    
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
                    NavigationLink {
                        WeekDetailView(
                            weekStart: item.weekStart,
                            weekStartDay: weekStartDay,
                            allWeights: allWeights
                        )
                    } label: {
                        HStack {
                            Text(formatWeek(item.weekStart))
                            Spacer()
                            Text(formatChange(item.change))
                                .foregroundStyle(item.change < 0 ? .green : .orange)
                        }
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

// MARK: - Week Detail View

struct WeekDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var settings: [AppSettings]
    
    let weekStart: Date
    let weekStartDay: Weekday
    let allWeights: [WeightSample]
    
    private var appSettings: AppSettings? {
        settings.first
    }
    
    private var unitSystem: UnitSystem {
        appSettings?.unitSystemEnum ?? .metric
    }
    
    private var weekWeights: [WeightSample] {
        let calendar = Calendar.current
        
        // Calculate week end (start of next week)
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        // Filter weights that fall within this week
        return allWeights
            .filter { $0.date >= weekStart && $0.date < weekEnd }
            .sorted { $0.date < $1.date }
    }
    
    private var weekEndDate: Date {
        let calendar = Calendar.current
        // Get the day before the next week starts
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        return calendar.date(byAdding: .second, value: -1, to: nextWeek) ?? weekStart
    }
    
    private var yAxisBounds: (min: Double, max: Double) {
        let weights = weekWeights.map { displayValue(kilograms: $0.kilograms) }
        guard let dataMin = weights.min(), let dataMax = weights.max() else {
            return (min: 0, max: 100)
        }

        // Round down minimum to nearest whole number
        let finalMin = floor(dataMin)
        
        // Round up maximum to nearest whole number
        let finalMax = ceil(dataMax)

        return (min: finalMin, max: finalMax)
    }
    
    var body: some View {
        List {
            // Chart Section
            Section {
                if weekWeights.isEmpty {
                    Text("No weight data for this week.")
                        .foregroundStyle(.secondary)
                } else if weekWeights.count == 1 {
                    Text("Only one weight entry this week. Need at least 2 entries to show a trend.")
                        .foregroundStyle(.secondary)
                } else {
                    let bounds = yAxisBounds
                    Chart(weekWeights) { weight in
                        LineMark(
                            x: .value("Date", weight.date),
                            y: .value("Weight", displayValue(kilograms: weight.kilograms))
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Date", weight.date),
                            y: .value("Weight", displayValue(kilograms: weight.kilograms))
                        )
                        .foregroundStyle(.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartYScale(domain: bounds.min...bounds.max)
                    .frame(height: 200)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Weight Trend")
            } footer: {
                if !weekWeights.isEmpty {
                    let first = weekWeights.first!.kilograms
                    let last = weekWeights.last!.kilograms
                    let change = last - first
                    let sign = change >= 0 ? "+" : ""
                    Text("Week change: \(sign)\(formatWeight(kilograms: change))")
                }
            }
            
            // Weight Entries Section
            Section("Weight Entries") {
                if weekWeights.isEmpty {
                    Text("No entries for this week")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(weekWeights.enumerated()), id: \.element.id) { index, weight in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(formatDateTime(weight.date))
                                    .font(.headline)
                                Spacer()
                                Text(formatWeight(kilograms: weight.kilograms))
                                    .font(.headline)
                            }
                            
                            if index > 0 {
                                let prevWeight = weekWeights[index - 1]
                                let change = weight.kilograms - prevWeight.kilograms
                                let sign = change >= 0 ? "+" : ""
                                HStack {
                                    Text("Change from previous")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(sign)\(formatWeight(kilograms: change))")
                                        .font(.caption)
                                        .foregroundStyle(change < 0 ? .green : .orange)
                                }
                            } else {
                                Text("First entry this week")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(formatWeekRange())
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
    
    private func formatWeekRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: weekStart)
        let endStr = formatter.string(from: weekEndDate)
        return "\(startStr) - \(endStr)"
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func displayValue(kilograms: Double) -> Double {
        switch unitSystem {
        case .metric:
            return kilograms
        case .imperial:
            return kilograms * 2.20462262
        }
    }

    private func formatWeight(kilograms: Double) -> String {
        switch unitSystem {
        case .metric:
            return String(format: "%.1f kg", kilograms)
        case .imperial:
            return String(format: "%.1f lb", kilograms * 2.20462262)
        }
    }
}
