import SwiftUI
import SwiftData

// Combined entry for displaying weight and body fat together
struct HealthEntry: Identifiable {
    let id = UUID()
    let date: Date
    var weight: WeightSample?
    var bodyFat: BodyFatSample?
}

struct WeightDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var health: HealthKitViewModel
    @Binding var selectedDaysRange: Int
    
    @Query private var settings: [AppSettings]
    private var appSettings: AppSettings? { settings.first }
    
    private var filteredWeights: [WeightSample] {
        guard selectedDaysRange > 0 else { return health.allWeights }
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDaysRange, to: Date()) ?? Date()
        return health.allWeights.filter { $0.date >= cutoff }
    }

    private var filteredBodyFat: [BodyFatSample] {
        guard selectedDaysRange > 0 else { return health.allBodyFat }
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDaysRange, to: Date()) ?? Date()
        return health.allBodyFat.filter { $0.date >= cutoff }
    }

    private var unitSystem: UnitSystem {
        appSettings?.unitSystemEnum ?? .metric
    }
    
    // Combine weight and body fat entries by date
    private var combinedEntries: [HealthEntry] {
        var entriesByDate: [Date: HealthEntry] = [:]
        
        // Add all weight entries
        for weight in filteredWeights {
            let dateKey = Calendar.current.startOfDay(for: weight.date)
            if var entry = entriesByDate[dateKey] {
                entry.weight = weight
                entriesByDate[dateKey] = entry
            } else {
                entriesByDate[dateKey] = HealthEntry(date: weight.date, weight: weight, bodyFat: nil)
            }
        }
        
        // Add all body fat entries
        for bodyFat in filteredBodyFat {
            let dateKey = Calendar.current.startOfDay(for: bodyFat.date)
            if var entry = entriesByDate[dateKey] {
                entry.bodyFat = bodyFat
                entriesByDate[dateKey] = entry
            } else {
                entriesByDate[dateKey] = HealthEntry(date: bodyFat.date, weight: nil, bodyFat: bodyFat)
            }
        }
        
        // Sort by date descending (most recent first)
        return entriesByDate.values.sorted { $0.date > $1.date }
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

            if !combinedEntries.isEmpty {
                Section("Entries") {
                    ForEach(Array(combinedEntries.enumerated()), id: \.element.id) { index, entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(formattedDate(entry.date))
                                    .font(.headline)
                                Spacer()
                            }
                            
                            if let weight = entry.weight {
                                HStack {
                                    Text("Weight")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text(formatWeight(kilograms: weight.kilograms))
                                            .foregroundStyle(.primary)
                                        
                                        if let delta = calculateWeightDelta(for: index) {
                                            Text(String(format: "(%@%.1f)", delta >= 0 ? "+" : "", delta))
                                                .foregroundStyle(delta < 0 ? .green : .orange)
                                        }
                                    }
                                }
                                .font(.subheadline)
                            }
                            
                            if let bodyFat = entry.bodyFat {
                                HStack {
                                    Text("Body fat")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text(String(format: "%.1f%%", bodyFat.percent))
                                            .foregroundStyle(.primary)
                                        
                                        if let delta = calculateBodyFatDelta(for: index) {
                                            Text(String(format: "(%@%.1f)", delta >= 0 ? "+" : "", delta))
                                                .foregroundStyle(delta < 0 ? .green : .orange)
                                        }
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Weight & Body Fat")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
        .refreshable {
            let maxDays = appSettings?.healthDataMaxPullDays ?? 90
            let startDate = appSettings?.healthMonitoringStartDate
            await health.incrementalRefresh(maxDays: maxDays, startDate: startDate, minDisplayTime: 1.0)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let dayName = date.formatted(.dateTime.weekday(.abbreviated))
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        return "\(dayName), \(dateString)"
    }

    private func calculateWeightDelta(for index: Int) -> Double? {
        guard index < combinedEntries.count - 1 else { return nil }
        guard let currentWeight = combinedEntries[index].weight else { return nil }
        
        // Find the next entry with a weight value
        for nextIndex in (index + 1)..<combinedEntries.count {
            if let previousWeight = combinedEntries[nextIndex].weight {
                return currentWeight.kilograms - previousWeight.kilograms
            }
        }
        return nil
    }

    private func calculateBodyFatDelta(for index: Int) -> Double? {
        guard index < combinedEntries.count - 1 else { return nil }
        guard let currentBodyFat = combinedEntries[index].bodyFat else { return nil }
        
        // Find the next entry with a body fat value
        for nextIndex in (index + 1)..<combinedEntries.count {
            if let previousBodyFat = combinedEntries[nextIndex].bodyFat {
                return currentBodyFat.percent - previousBodyFat.percent
            }
        }
        return nil
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

