import Foundation

struct WeightAnalysisService {
    /// Calculate the week start date for a given date based on custom week start day
    /// - Parameters:
    ///   - date: The date to find the week start for
    ///   - weekStartDay: The day that should be considered the start of the week
    /// - Returns: The date representing the start of the week (at 00:00:00)
    private static func weekStart(for date: Date, startingOn weekStartDay: Weekday) -> Date {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        let targetWeekday = weekStartDay.calendarWeekday
        
        // Calculate days to subtract to get to the week start
        var daysBack: Int = currentWeekday - targetWeekday
        if daysBack < 0 {
            daysBack += 7
        }
        
        // Get the start of the day, then go back the calculated days
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: -daysBack, to: startOfDay) ?? startOfDay
    }
    
    /// Calculate weekly weight trend (absolute weight values by week)
    static func weeklyWeightTrend(weights: [WeightSample], weekStartDay: Weekday = .monday) -> [(weekStart: Date, weight: Double)] {
        guard !weights.isEmpty else { return [] }
        
        let sortedWeights = weights.sorted { $0.date < $1.date }
        
        // Group weights by custom week
        var weeklyGroups: [Date: [WeightSample]] = [:]
        for weight in sortedWeights {
            let weekStartDate = weekStart(for: weight.date, startingOn: weekStartDay)
            weeklyGroups[weekStartDate, default: []].append(weight)
        }
        
        // Get average weight for each week
        var results: [(weekStart: Date, weight: Double)] = []
        for (weekStartDate, weekWeights) in weeklyGroups.sorted(by: { $0.key < $1.key }) {
            let avgWeight = weekWeights.map { $0.kilograms }.reduce(0, +) / Double(weekWeights.count)
            results.append((weekStart: weekStartDate, weight: avgWeight))
        }
        
        return results.suffix(12) // Last 12 weeks
    }
    
    /// Calculate weight change for each week
    static func weeklyChanges(weights: [WeightSample], weekStartDay: Weekday = .monday) -> [(weekStart: Date, change: Double)] {
        guard !weights.isEmpty else { return [] }
        
        let sortedWeights = weights.sorted { $0.date < $1.date }
        
        // Group weights by custom week
        var weeklyGroups: [Date: [WeightSample]] = [:]
        for weight in sortedWeights {
            let weekStartDate = weekStart(for: weight.date, startingOn: weekStartDay)
            weeklyGroups[weekStartDate, default: []].append(weight)
        }
        
        // Calculate change for each week (first weight to last weight in that week)
        var results: [(weekStart: Date, change: Double)] = []
        for (weekStartDate, weekWeights) in weeklyGroups.sorted(by: { $0.key < $1.key }) {
            guard let first = weekWeights.first, let last = weekWeights.last else { continue }
            let change = last.kilograms - first.kilograms
            results.append((weekStart: weekStartDate, change: change))
        }
        
        return results.suffix(12) // Last 12 weeks
    }
    
    /// Calculate average weight change by day of week
    static func averageChangeByDayOfWeek(weights: [WeightSample], weekStartDay: Weekday = .monday) -> [(dayOfWeek: Int, dayName: String, avgChange: Double)] {
        guard weights.count >= 2 else { return [] }
        
        let sortedWeights = weights.sorted { $0.date < $1.date }
        let calendar = Calendar.current
        
        // Calculate daily changes
        var changesByDay: [Int: [Double]] = [:]
        for i in 1..<sortedWeights.endIndex {
            let prevWeight = sortedWeights[i-1]
            let currWeight = sortedWeights[i]
            
            let dayOfWeek = calendar.component(.weekday, from: currWeight.date)
            let change = currWeight.kilograms - prevWeight.kilograms
            
            changesByDay[dayOfWeek, default: []].append(change)
        }
        
        // Calculate averages for all days
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var allDays: [(dayOfWeek: Int, dayName: String, avgChange: Double)] = []
        
        for dayOfWeek in 1...7 {
            if let changes = changesByDay[dayOfWeek], !changes.isEmpty {
                let avg = changes.reduce(0, +) / Double(changes.count)
                let dayName = dayNames[dayOfWeek - 1]
                allDays.append((dayOfWeek: dayOfWeek, dayName: dayName, avgChange: avg))
            } else {
                // Include days with no data as 0
                let dayName = dayNames[dayOfWeek - 1]
                allDays.append((dayOfWeek: dayOfWeek, dayName: dayName, avgChange: 0))
            }
        }
        
        // Reorder to start from the configured week start day
        let startDayWeekday = weekStartDay.calendarWeekday
        var reordered: [(dayOfWeek: Int, dayName: String, avgChange: Double)] = []
        
        for offset in 0..<7 {
            let targetWeekday = ((startDayWeekday - 1 + offset) % 7) + 1
            if let day = allDays.first(where: { $0.dayOfWeek == targetWeekday }) {
                reordered.append(day)
            }
        }
        
        return reordered
    }
    
    /// Calculate daily weight change patterns (which specific days show most change)
    static func dailyWeightChanges(weights: [WeightSample]) -> [(date: Date, change: Double)] {
        guard weights.count >= 2 else { return [] }
        
        let sortedWeights = weights.sorted { $0.date < $1.date }
        var results: [(date: Date, change: Double)] = []
        
        for i in 1..<sortedWeights.endIndex {
            let prevWeight = sortedWeights[i-1]
            let currWeight = sortedWeights[i]
            let change = currWeight.kilograms - prevWeight.kilograms
            results.append((date: currWeight.date, change: change))
        }
        
        return results
    }
}
