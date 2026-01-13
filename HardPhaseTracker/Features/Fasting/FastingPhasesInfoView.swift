import SwiftUI

struct FastingPhaseInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Phase Information
                    ForEach(Array(FastingPhaseInfo.phases.enumerated()), id: \.element.name) { index, phase in
                        PhaseCard(phase: phase)
                    }
                    
                    // Pros and Cons
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fasting Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(FastingPhaseInfo.prosAndCons, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: section.icon)
                                        .foregroundStyle(iconColor(for: section.title))
                                    Text(section.title)
                                        .font(.headline)
                                }
                                
                                ForEach(section.items, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(item)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    
                    // Medical Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Medical Disclaimer")
                                .font(.headline)
                        }
                        
                        Text(FastingPhaseInfo.medicalDisclaimer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.yellow.opacity(0.12))
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("Fasting Phases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconColor(for title: String) -> Color {
        switch title {
        case "Benefits": return .green
        case "Drawbacks": return .orange
        case "The Bottom Line": return .blue
        default: return .secondary
        }
    }
}

private struct PhaseCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: FastingPhaseInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(phase.emoji)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(phaseNumber): \(phase.name)")
                        .font(.headline)
                    
                    Text(phase.hourRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(phase.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(phase.details, id: \.self) { detail in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(detail)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.footnote)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(phaseColor.opacity(0.12))
        )
    }
    
    private var phaseNumber: Int {
        FastingPhaseInfo.phases.firstIndex(where: { $0.name == phase.name }).map { $0 + 1 } ?? 0
    }
    
    private var phaseColor: Color {
        phase.color(for: colorScheme)
    }
}

#Preview {
    FastingPhaseInfoView()
}
