import Foundation
import SwiftData
import OSLog
import UniformTypeIdentifiers

/// Service for exporting and importing all app data as JSON
@MainActor
final class DataExportImportService {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "DataExportImport")
    
    // MARK: - Export Data Structure
    
    struct ExportData: Codable {
        let version: Int
        let exportDate: Date
        let appVersion: String
        
        let mealTemplates: [ExportMealTemplate]
        let mealComponents: [ExportMealComponent]
        let mealLogEntries: [ExportMealLogEntry]
        let electrolyteIntakeEntries: [ExportElectrolyteIntakeEntry]
        let electrolyteTargetSettings: [ExportElectrolyteTargetSetting]
        let eatingWindowSchedules: [ExportEatingWindowSchedule]
        let appSettings: ExportAppSettings?
    }
    
    struct ExportMealTemplate: Codable, Identifiable {
        let id: String
        let name: String
        let protein: Double
        let carbs: Double
        let fats: Double
        let kind: String?
    }
    
    struct ExportMealComponent: Codable, Identifiable {
        let id: String
        let name: String
        let grams: Double
        let unit: String?
        let templateId: String?
    }
    
    struct ExportMealLogEntry: Codable, Identifiable {
        let id: String
        let timestamp: Date
        let timeZoneIdentifier: String
        let utcOffsetSeconds: Int
        let templateId: String?
        let notes: String?
    }
    
    struct ExportElectrolyteIntakeEntry: Codable, Identifiable {
        let id: String
        let timestamp: Date
        let dayStart: Date
        let slotIndex: Int
        let templateId: String?
    }
    
    struct ExportElectrolyteTargetSetting: Codable, Identifiable {
        let id: String
        let effectiveDate: Date
        let servingsPerDay: Int
    }
    
    struct ExportEatingWindowSchedule: Codable, Identifiable {
        let id: String
        let name: String
        let startMinutes: Int
        let endMinutes: Int
        let weekdayMask: Int
        let isBuiltIn: Bool
    }
    
    struct ExportAppSettings: Codable {
        let selectedScheduleId: String?
        let alwaysShowLogMealButton: Bool
        let logMealShowBeforeHours: Double
        let logMealShowAfterHours: Double
        let dashboardMealListCount: Int?
        let mealTimeDisplayMode: String?
        let mealTimeZoneBadgeStyle: String?
        let mealTimeOffsetStyle: String?
        let electrolyteTemplateIds: [String]
        let electrolyteSelectionMode: String?
        let unitSystem: String?
        let weeklyProteinGoalGrams: Double?
        let weightGoalKg: Double?
        let healthMonitoringStartDate: Date?
        let healthDataMaxPullDays: Int?
    }
    
    // MARK: - Export
    
    static func exportAllData(modelContext: ModelContext) throws -> Data {
        logger.info("Starting data export...")
        
        // Fetch all data
        let mealTemplates = try modelContext.fetch(FetchDescriptor<MealTemplate>())
        let mealComponents = try modelContext.fetch(FetchDescriptor<MealComponent>())
        let mealLogEntries = try modelContext.fetch(FetchDescriptor<MealLogEntry>())
        let electrolyteIntakeEntries = try modelContext.fetch(FetchDescriptor<ElectrolyteIntakeEntry>())
        let electrolyteTargetSettings = try modelContext.fetch(FetchDescriptor<ElectrolyteTargetSetting>())
        let eatingWindowSchedules = try modelContext.fetch(FetchDescriptor<EatingWindowSchedule>())
        let appSettings = try modelContext.fetch(FetchDescriptor<AppSettings>()).first
        
        // Create ID mapping for relationships
        var templateIdMap: [PersistentIdentifier: String] = [:]
        var scheduleIdMap: [PersistentIdentifier: String] = [:]
        
        // Export meal templates
        let exportedTemplates = mealTemplates.map { template -> ExportMealTemplate in
            let id = UUID().uuidString
            templateIdMap[template.persistentModelID] = id
            return ExportMealTemplate(
                id: id,
                name: template.name,
                protein: template.protein,
                carbs: template.carbs,
                fats: template.fats,
                kind: template.kind
            )
        }
        
        // Export meal components
        let exportedComponents = mealComponents.map { component -> ExportMealComponent in
            ExportMealComponent(
                id: UUID().uuidString,
                name: component.name,
                grams: component.grams,
                unit: component.unit,
                templateId: component.template.flatMap { templateIdMap[$0.persistentModelID] }
            )
        }
        
        // Export meal log entries
        let exportedMealLogs = mealLogEntries.map { entry -> ExportMealLogEntry in
            ExportMealLogEntry(
                id: UUID().uuidString,
                timestamp: entry.timestamp,
                timeZoneIdentifier: entry.timeZoneIdentifier,
                utcOffsetSeconds: entry.utcOffsetSeconds,
                templateId: entry.template.flatMap { templateIdMap[$0.persistentModelID] },
                notes: entry.notes
            )
        }
        
        // Export electrolyte intake entries
        let exportedElectrolyteIntakes = electrolyteIntakeEntries.map { entry -> ExportElectrolyteIntakeEntry in
            ExportElectrolyteIntakeEntry(
                id: UUID().uuidString,
                timestamp: entry.timestamp,
                dayStart: entry.dayStart,
                slotIndex: entry.slotIndex,
                templateId: entry.template.flatMap { templateIdMap[$0.persistentModelID] }
            )
        }
        
        // Export electrolyte target settings
        let exportedElectrolyteTargets = electrolyteTargetSettings.map { setting -> ExportElectrolyteTargetSetting in
            ExportElectrolyteTargetSetting(
                id: UUID().uuidString,
                effectiveDate: setting.effectiveDate,
                servingsPerDay: setting.servingsPerDay
            )
        }
        
        // Export eating window schedules
        let exportedSchedules = eatingWindowSchedules.map { schedule -> ExportEatingWindowSchedule in
            let id = UUID().uuidString
            scheduleIdMap[schedule.persistentModelID] = id
            return ExportEatingWindowSchedule(
                id: id,
                name: schedule.name,
                startMinutes: schedule.startMinutes,
                endMinutes: schedule.endMinutes,
                weekdayMask: schedule.weekdayMask,
                isBuiltIn: schedule.isBuiltIn
            )
        }
        
        // Export app settings
        let exportedSettings: ExportAppSettings? = appSettings.map { settings in
            let electrolyteTemplateIds = (settings.electrolyteTemplates ?? []).compactMap { template in
                templateIdMap[template.persistentModelID]
            }
            
            return ExportAppSettings(
                selectedScheduleId: settings.selectedSchedule.flatMap { scheduleIdMap[$0.persistentModelID] },
                alwaysShowLogMealButton: settings.alwaysShowLogMealButton,
                logMealShowBeforeHours: settings.logMealShowBeforeHours,
                logMealShowAfterHours: settings.logMealShowAfterHours,
                dashboardMealListCount: settings.dashboardMealListCount,
                mealTimeDisplayMode: settings.mealTimeDisplayMode,
                mealTimeZoneBadgeStyle: settings.mealTimeZoneBadgeStyle,
                mealTimeOffsetStyle: settings.mealTimeOffsetStyle,
                electrolyteTemplateIds: electrolyteTemplateIds,
                electrolyteSelectionMode: settings.electrolyteSelectionMode,
                unitSystem: settings.unitSystem,
                weeklyProteinGoalGrams: settings.weeklyProteinGoalGrams,
                weightGoalKg: settings.weightGoalKg,
                healthMonitoringStartDate: settings.healthMonitoringStartDate,
                healthDataMaxPullDays: settings.healthDataMaxPullDays
            )
        }
        
        // Create export data
        let exportData = ExportData(
            version: 1,
            exportDate: Date(),
            appVersion: AppVersion.fullVersionString,
            mealTemplates: exportedTemplates,
            mealComponents: exportedComponents,
            mealLogEntries: exportedMealLogs,
            electrolyteIntakeEntries: exportedElectrolyteIntakes,
            electrolyteTargetSettings: exportedElectrolyteTargets,
            eatingWindowSchedules: exportedSchedules,
            appSettings: exportedSettings
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        logger.info("Data export completed: \(mealTemplates.count) templates, \(mealLogEntries.count) log entries")
        
        return jsonData
    }
    
    // MARK: - Import
    
    enum ImportError: LocalizedError {
        case unsupportedVersion(Int)
        case invalidData
        case relationshipMismatch
        
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Unsupported export version: \(version). This app only supports version 1."
            case .invalidData:
                return "The import file is invalid or corrupted."
            case .relationshipMismatch:
                return "The import file contains invalid relationships."
            }
        }
    }
    
    struct ImportResult {
        let templatesImported: Int
        let componentsImported: Int
        let mealLogsImported: Int
        let electrolyteIntakesImported: Int
        let electrolyteTargetsImported: Int
        let schedulesImported: Int
        let settingsImported: Bool
        
        var summary: String {
            """
            Import completed:
            • \(templatesImported) meal templates
            • \(componentsImported) meal components
            • \(mealLogsImported) meal log entries
            • \(electrolyteIntakesImported) electrolyte intakes
            • \(electrolyteTargetsImported) electrolyte targets
            • \(schedulesImported) eating window schedules
            • Settings: \(settingsImported ? "imported" : "not imported")
            """
        }
    }
    
    static func importAllData(from jsonData: Data, into modelContext: ModelContext, mergeStrategy: ImportMergeStrategy = .replace) throws -> ImportResult {
        logger.info("Starting data import...")
        
        // Decode JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData: ExportData
        do {
            exportData = try decoder.decode(ExportData.self, from: jsonData)
        } catch {
            logger.error("Failed to decode import data: \(error.localizedDescription)")
            throw ImportError.invalidData
        }
        
        // Validate version
        guard exportData.version == 1 else {
            throw ImportError.unsupportedVersion(exportData.version)
        }
        
        logger.info("Importing data from export dated \(exportData.exportDate)")
        
        // Apply merge strategy
        if mergeStrategy == .replace {
            try clearAllData(modelContext: modelContext)
        }
        
        // Create new objects and track ID mappings
        var templateMap: [String: MealTemplate] = [:]
        var scheduleMap: [String: EatingWindowSchedule] = [:]
        
        // Import eating window schedules first (no dependencies)
        for exportSchedule in exportData.eatingWindowSchedules {
            let schedule = EatingWindowSchedule(
                name: exportSchedule.name,
                startMinutes: exportSchedule.startMinutes,
                endMinutes: exportSchedule.endMinutes,
                weekdayMask: exportSchedule.weekdayMask,
                isBuiltIn: exportSchedule.isBuiltIn
            )
            modelContext.insert(schedule)
            scheduleMap[exportSchedule.id] = schedule
        }
        
        // Import meal templates (no dependencies)
        for exportTemplate in exportData.mealTemplates {
            let template = MealTemplate(
                name: exportTemplate.name,
                protein: exportTemplate.protein,
                carbs: exportTemplate.carbs,
                fats: exportTemplate.fats,
                kind: exportTemplate.kind,
                components: []
            )
            modelContext.insert(template)
            templateMap[exportTemplate.id] = template
        }
        
        // Import meal components (depends on templates)
        for exportComponent in exportData.mealComponents {
            let component = MealComponent(
                name: exportComponent.name,
                grams: exportComponent.grams,
                unit: exportComponent.unit ?? "g"
            )
            
            if let templateId = exportComponent.templateId,
               let template = templateMap[templateId] {
                component.template = template
            }
            
            modelContext.insert(component)
        }
        
        // Import meal log entries (depends on templates)
        for exportEntry in exportData.mealLogEntries {
            let template = exportEntry.templateId.flatMap { templateMap[$0] }
            
            let entry = MealLogEntry(
                timestamp: exportEntry.timestamp,
                timeZoneIdentifier: exportEntry.timeZoneIdentifier,
                utcOffsetSeconds: exportEntry.utcOffsetSeconds,
                template: template,
                notes: exportEntry.notes
            )
            modelContext.insert(entry)
        }
        
        // Import electrolyte intake entries (depends on templates)
        for exportEntry in exportData.electrolyteIntakeEntries {
            let template = exportEntry.templateId.flatMap { templateMap[$0] }
            
            let entry = ElectrolyteIntakeEntry(
                timestamp: exportEntry.timestamp,
                slotIndex: exportEntry.slotIndex,
                template: template
            )
            modelContext.insert(entry)
        }
        
        // Import electrolyte target settings (no dependencies)
        for exportTarget in exportData.electrolyteTargetSettings {
            let target = ElectrolyteTargetSetting(
                effectiveDate: exportTarget.effectiveDate,
                servingsPerDay: exportTarget.servingsPerDay
            )
            modelContext.insert(target)
        }
        
        // Import app settings (depends on schedules and templates)
        var settingsImported = false
        if let exportSettings = exportData.appSettings {
            let settings = AppSettings()
            
            settings.selectedSchedule = exportSettings.selectedScheduleId.flatMap { scheduleMap[$0] }
            settings.alwaysShowLogMealButton = exportSettings.alwaysShowLogMealButton
            settings.logMealShowBeforeHours = exportSettings.logMealShowBeforeHours
            settings.logMealShowAfterHours = exportSettings.logMealShowAfterHours
            settings.dashboardMealListCount = exportSettings.dashboardMealListCount
            settings.mealTimeDisplayMode = exportSettings.mealTimeDisplayMode
            settings.mealTimeZoneBadgeStyle = exportSettings.mealTimeZoneBadgeStyle
            settings.mealTimeOffsetStyle = exportSettings.mealTimeOffsetStyle
            settings.electrolyteSelectionMode = exportSettings.electrolyteSelectionMode
            settings.unitSystem = exportSettings.unitSystem
            settings.weeklyProteinGoalGrams = exportSettings.weeklyProteinGoalGrams
            settings.weightGoalKg = exportSettings.weightGoalKg
            settings.healthMonitoringStartDate = exportSettings.healthMonitoringStartDate
            settings.healthDataMaxPullDays = exportSettings.healthDataMaxPullDays
            
            // Link electrolyte templates
            let electrolyteTemplates = exportSettings.electrolyteTemplateIds.compactMap { templateMap[$0] }
            settings.electrolyteTemplates = electrolyteTemplates
            
            modelContext.insert(settings)
            settingsImported = true
        }
        
        // Save all changes
        try modelContext.save()
        
        let result = ImportResult(
            templatesImported: exportData.mealTemplates.count,
            componentsImported: exportData.mealComponents.count,
            mealLogsImported: exportData.mealLogEntries.count,
            electrolyteIntakesImported: exportData.electrolyteIntakeEntries.count,
            electrolyteTargetsImported: exportData.electrolyteTargetSettings.count,
            schedulesImported: exportData.eatingWindowSchedules.count,
            settingsImported: settingsImported
        )
        
        logger.info("Data import completed: \(result.summary)")
        
        return result
    }
    
    // MARK: - Merge Strategy
    
    enum ImportMergeStrategy {
        case replace // Delete all existing data before import
        case merge   // Keep existing data and add imported data
    }
    
    // MARK: - Helper Methods
    
    private static func clearAllData(modelContext: ModelContext) throws {
        logger.warning("Clearing all existing data...")
        
        // Delete in reverse dependency order
        try modelContext.delete(model: AppSettings.self)
        try modelContext.delete(model: ElectrolyteIntakeEntry.self)
        try modelContext.delete(model: MealLogEntry.self)
        try modelContext.delete(model: MealComponent.self)
        try modelContext.delete(model: ElectrolyteTargetSetting.self)
        try modelContext.delete(model: MealTemplate.self)
        try modelContext.delete(model: EatingWindowSchedule.self)
        
        try modelContext.save()
        
        logger.info("All existing data cleared")
    }
    
    static func generateExportFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        return "HardPhaseTracker_backup_\(dateString).json"
    }
}

// MARK: - UTType Extension

extension UTType {
    static let hardPhaseTrackerBackup = UTType(exportedAs: "com.gordonbeeming.hardphasetracker.backup", conformingTo: .json)
}
