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
                ForEach(filteredWeights.reversed()) { sample in
                    LabeledContent(
                        sample.date.formatted(date: .abbreviated, time: .omitted),
                        value: String(format: "%.1f kg", sample.kilograms)
                    )
                }
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(colorScheme))
    }
}
