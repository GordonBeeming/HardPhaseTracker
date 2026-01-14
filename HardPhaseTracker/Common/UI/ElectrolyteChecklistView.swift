import SwiftUI
import SwiftData

struct ElectrolyteChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let date: Date
    let settings: AppSettings?

    @Query private var entries: [ElectrolyteIntakeEntry]

    @Query(sort: [SortDescriptor(\ElectrolyteTargetSetting.effectiveDate)])
    private var targets: [ElectrolyteTargetSetting]

    @State private var pickingSlotIndex: Int?

    init(date: Date, settings: AppSettings?) {
        self.date = date
        self.settings = settings

        let day = Calendar.current.startOfDay(for: date)
        _entries = Query(
            filter: #Predicate<ElectrolyteIntakeEntry> { $0.dayStart == day },
            sort: [SortDescriptor(\ElectrolyteIntakeEntry.slotIndex)]
        )
    }

    var body: some View {
        let target = ElectrolyteTargetService.servingsPerDay(for: date, targets: targets)
        // Show enough slots to accommodate both the target and any extra entries that were logged
        // This prevents "hiding" entries if someone logged more than the current target
        let effectiveTarget = max(target, entries.count)
        
        // Check if entries exceed target
        let isOverTarget = entries.count > target && target > 0

        if effectiveTarget <= 0 {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Electrolytes")
                        .font(.headline)

                    Spacer()

                    Text("\(entries.count)/\(target)")
                        .foregroundStyle(isOverTarget ? .orange : .secondary)
                        .font(.subheadline)
                }
                
                if isOverTarget {
                    Text("You've exceeded your daily target of \(target)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if availableTemplates.isEmpty {
                    Text("Select your electrolyte(s) in Settings to enable ticking.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                let slots = Array(0..<effectiveTarget)
                if effectiveTarget < 5 {
                    HStack(spacing: 10) {
                        ForEach(slots, id: \.self) { i in
                            slotButton(i)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(slots, id: \.self) { i in
                            slotRow(i)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground(colorScheme))
            )
            .confirmationDialog(
                "Select electrolyte",
                isPresented: Binding(
                    get: { pickingSlotIndex != nil },
                    set: { if !$0 { pickingSlotIndex = nil } }
                )
            ) {
                ForEach(availableTemplates) { t in
                    Button(t.name) {
                        if let idx = pickingSlotIndex {
                            log(slotIndex: idx, template: t)
                        }
                        pickingSlotIndex = nil
                    }
                }

                Button("Cancel", role: .cancel) {
                    pickingSlotIndex = nil
                }
            }
        }
    }

    private var availableTemplates: [MealTemplate] {
        (settings?.electrolyteTemplates ?? []).sorted { $0.name < $1.name }
    }

    @ViewBuilder
    private func slotButton(_ index: Int) -> some View {
        let isTaken = entry(for: index) != nil
        Button {
            toggle(slotIndex: index)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTaken ? Color.green.opacity(0.16) : Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(availableTemplates.isEmpty)
    }

    @ViewBuilder
    private func slotRow(_ index: Int) -> some View {
        let entry = entry(for: index)
        let isTaken = entry != nil
        Button {
            toggle(slotIndex: index)
        } label: {
            HStack {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                Text("Serving \(index + 1)")
                Spacer()
                Text(entry?.template?.name ?? (isTaken ? "Taken" : ""))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(availableTemplates.isEmpty)
    }

    private func entry(for slotIndex: Int) -> ElectrolyteIntakeEntry? {
        entries.first(where: { $0.slotIndex == slotIndex })
    }

    private func toggle(slotIndex: Int) {
        if let existing = entry(for: slotIndex) {
            modelContext.delete(existing)
            modelContext.saveLogged()
            return
        }

        guard !availableTemplates.isEmpty else { return }

        let mode = settings?.electrolyteSelectionMode ?? "fixed"

        if mode == "askEachTime" {
            pickingSlotIndex = slotIndex
            return
        }

        if availableTemplates.count == 1 {
            log(slotIndex: slotIndex, template: availableTemplates.first)
        } else {
            pickingSlotIndex = slotIndex
        }
    }

    private func log(slotIndex: Int, template: MealTemplate?) {
        let day = Calendar.current.startOfDay(for: date)
        let timestamp = Date()

        let entry = ElectrolyteIntakeEntry(timestamp: timestamp, slotIndex: slotIndex, template: template)
        entry.dayStart = day
        modelContext.insert(entry)
        modelContext.saveLogged()
    }
}

#Preview {
    ElectrolyteChecklistView(date: Date(), settings: nil)
}
