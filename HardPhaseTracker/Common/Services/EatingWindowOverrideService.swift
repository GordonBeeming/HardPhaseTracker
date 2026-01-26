import Foundation
import SwiftData

struct EatingWindowOverrideService {
    
    // MARK: - Create/Update
    
    static func createOrUpdateOverride(
        date: Date,
        type: OverrideType,
        schedule: EatingWindowSchedule?,
        startMinutes: Int?,
        endMinutes: Int?,
        modelContext: ModelContext
    ) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        // Check if override already exists for this date
        let descriptor = FetchDescriptor<EatingWindowOverride>(
            predicate: #Predicate<EatingWindowOverride> { override in
                override.date == normalizedDate
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            // Update existing
            existing.overrideType = type.rawValue
            existing.startMinutes = startMinutes
            existing.endMinutes = endMinutes
            existing.schedule = schedule
        } else {
            // Create new
            let override = EatingWindowOverride(
                date: normalizedDate,
                overrideType: type,
                schedule: schedule,
                startMinutes: startMinutes,
                endMinutes: endMinutes
            )
            modelContext.insert(override)
        }
        
        modelContext.saveLogged()
    }
    
    // MARK: - Read
    
    static func getOverride(for date: Date, modelContext: ModelContext) -> EatingWindowOverride? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<EatingWindowOverride>(
            predicate: #Predicate<EatingWindowOverride> { override in
                override.date == normalizedDate
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    static func getOverrides(in range: ClosedRange<Date>, modelContext: ModelContext) -> [EatingWindowOverride] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: range.lowerBound)
        let endDate = calendar.startOfDay(for: range.upperBound)
        
        let descriptor = FetchDescriptor<EatingWindowOverride>(
            predicate: #Predicate<EatingWindowOverride> { override in
                override.date >= startDate && override.date <= endDate
            },
            sortBy: [SortDescriptor(\EatingWindowOverride.date, order: .forward)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Delete
    
    static func deleteOverride(_ override: EatingWindowOverride, modelContext: ModelContext) {
        modelContext.delete(override)
        modelContext.saveLogged()
    }
    
    // MARK: - Cleanup
    
    static func clearOldOverrides(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<EatingWindowOverride>(
            predicate: #Predicate<EatingWindowOverride> { override in
                override.date < today
            }
        )
        
        if let oldOverrides = try? modelContext.fetch(descriptor) {
            for override in oldOverrides {
                modelContext.delete(override)
            }
            if !oldOverrides.isEmpty {
                modelContext.saveLogged()
            }
        }
    }
}
