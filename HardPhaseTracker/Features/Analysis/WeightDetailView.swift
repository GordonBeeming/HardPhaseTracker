import SwiftUI

struct WeightDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let weights: [WeightSample]
    @Binding var selectedDaysRange: Int
    
    private var filteredWeights: [WeightSample] {
        guard selectedDaysRange > 0 else { return weights }
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDaysRange, to: Date()) ?? Date()
        return weights.filter { $0.date >= cutoff }
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
                ForEach(Array(filteredWeights.reversed().enumerated()), id: \.element.id) { index, sample in
                    LabeledContent(sample.date.formatted(date: .abbreviated, time: .omitted)) {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f kg", sample.kilograms))
                                .foregroundStyle(.primary)
                            
                            // Show delta from previous weight (next in reversed array)
                            if let delta = calculateDelta(for: index, reversed: filteredWeights.reversed()) {
                                Text(String(format: "(%@%.1f)", delta >= 0 ? "+" : "", delta))
                                    .foregroundStyle(delta < 0 ? .green : .orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
    
    private func calculateDelta(for index: Int, reversed: [WeightSample]) -> Double? {
        guard index < reversed.count - 1 else { return nil }
        let current = reversed[index]
        let previous = reversed[index + 1]
        return current.kilograms - previous.kilograms
    }
}
