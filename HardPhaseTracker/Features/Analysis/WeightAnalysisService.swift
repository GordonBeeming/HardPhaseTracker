import Foundation

struct WeightAnalysisService {
    /// Calculate weight change for each week
    static func weeklyChanges(weights: [WeightSample]) -> [(weekStart: Date, change: Double)] {
        guard !weights.isEmpty else { return [] }
        
        let sortedWeights = weights.sorted { $0.date < $1.date }
        let calendar = Calendar.current
        
        // Group weights by week
        var weeklyGroups: [Date: [WeightSample]] = [:]
        for weight in sortedWeights {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weight.date)) ?? weight.date
            weeklyGroups[weekStart, default: []].append(weight)
        }
        
        // Calculate change for each week
        var results: [(weekStart: Date, change: Double)] = []
        for (weekStart, weekWeights) in weeklyGroups.sorted(by: { $0.key < $1.key }) {
            guard let first = weekWeights.first, let last = weekWeights.last else { continue }
            let change = last.kilograms - first.kilograms
            results.append((weekStart: weekStart, change: change))
        }
        
        return results.suffix(12) // Last 12 weeks
    }
    
    /// Calculate average weight change by day of week
    static func averageChangeByDayOfWeek(weights: [WeightSample]) -> [(dayOfWeek: Int, dayName: String, avgChange: Double)] {
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
        
        // Calculate averages
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var results: [(dayOfWeek: Int, dayName: String, avgChange: Double)] = []
        
        for dayOfWeek in 1...7 {
            if let changes = changesByDay[dayOfWeek], !changes.isEmpty {
                let avg = changes.reduce(0, +) / Double(changes.count)
                let dayName = dayNames[dayOfWeek - 1]
                results.append((dayOfWeek: dayOfWeek, dayName: dayName, avgChange: avg))
            }
        }
        
        return results.sorted { $0.dayOfWeek < $1.dayOfWeek }
    }
}
