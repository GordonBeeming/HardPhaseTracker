import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    @Query private var settings: [AppSettings]
    @Query(sort: [SortDescriptor(\MealTemplate.name)]) private var templates: [MealTemplate]
    @Query(sort: [SortDescriptor(\ElectrolyteTargetSetting.effectiveDate)]) private var electrolyteTargets: [ElectrolyteTargetSetting]

    private enum SectionTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case meals = "Meals"
        case electrolytes = "Electrolytes"
        case notifications = "Notifications"
        case health = "Health"
        case data = "Data"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .dashboard: "rectangle.3.group"
            case .meals: "fork.knife"
            case .electrolytes: "drop"
            case .notifications: "bell"
            case .health: "heart"
            case .data: "arrow.down.doc"
            }
        }
    }

    @State private var selectedTab: SectionTab? = .dashboard
    @StateObject private var health = HealthKitViewModel()
    @StateObject private var cloudKitSync = CloudKitSyncService()
    @State private var isRefreshingHealth = false

    // Dashboard
    @State private var alwaysShowLogMeal = false
    @State private var beforeHours: Double = 0.5 // 30 minutes
    @State private var afterHours: Double = 2.5
    @State private var dashboardMealListCount: Int = 10

    // Meals / time
    @State private var mealTimeDisplayMode: MealTimeDisplayMode = .captured

    // Electrolytes
    @State private var electrolyteServingsPerDay: Int = 0
    @State private var electrolyteAskEachTime: Bool = false

    // Global
    @State private var unitSystem: UnitSystem = .metric

    // Health
    @State private var weightGoalDisplay: Double = 0 // Display value in user's unit
    @State private var healthMonitoringStartDate: Date = Date()
    @State private var healthDataMaxPullDays: Int = 90
    @State private var weekStartDay: Weekday = .monday
    
    // Data export/import
    @State private var showingExportShare = false
    @State private var showingImportPicker = false
    @State private var showingImportConfirmation = false
    @State private var showingImportResult = false
    @State private var exportedData: Data?
    @State private var importedData: Data?
    @State private var importResult: DataExportImportService.ImportResult?
    @State private var importError: Error?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isPickingSchedule = false
    @State private var includeHealthDataInExport = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(SectionTab.allCases, selection: $selectedTab) { t in
                        Label(t.rawValue, systemImage: t.systemImage)
                    }
                    .navigationTitle("Settings")
                    .safeAreaInset(edge: .bottom) {
                        versionFooter
                    }
                } detail: {
                    settingsDetail(tab: currentTab)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            } else {
                NavigationStack {
                    List(SectionTab.allCases) { t in
                        NavigationLink(value: t) {
                            Label(t.rawValue, systemImage: t.systemImage)
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationDestination(for: SectionTab.self) { t in
                        settingsDetail(tab: t)
                    }
                    .safeAreaInset(edge: .bottom) {
                        versionFooter
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                }
            }
        }
        .onAppear {
            let current = settings.first ?? AppSettings()
            if settings.isEmpty { modelContext.insert(current) }

            alwaysShowLogMeal = current.alwaysShowLogMealButton
            beforeHours = current.logMealShowBeforeHours
            afterHours = current.logMealShowAfterHours

            mealTimeDisplayMode = current.mealTimeDisplayModeEnum
            // timezone badge style setting removed (only one supported style)
            dashboardMealListCount = current.dashboardMealListCount ?? 10

            unitSystem = current.unitSystemEnum

            let weightGoalKg = current.weightGoalKg ?? 0
            weightGoalDisplay = unitSystem == .metric ? weightGoalKg : weightGoalKg * 2.20462262

            healthMonitoringStartDate = current.healthMonitoringStartDate ?? Date()
            healthDataMaxPullDays = current.healthDataMaxPullDays ?? 90
            weekStartDay = current.weekStartDayEnum

            electrolyteServingsPerDay = ElectrolyteTargetService.servingsPerDay(for: Date(), targets: electrolyteTargets)
            electrolyteAskEachTime = (current.electrolyteSelectionMode ?? "fixed") == "askEachTime"

            Task { await health.refreshPermissionOnly() }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .health {
                Task { await health.refreshPermissionOnly() }
            }
        }
        .onChange(of: alwaysShowLogMeal) { _, _ in save() }
        .onChange(of: beforeHours) { _, _ in save() }
        .onChange(of: afterHours) { _, _ in save() }
        .onChange(of: dashboardMealListCount) { _, _ in save() }
        .onChange(of: mealTimeDisplayMode) { _, _ in save() }
        .onChange(of: electrolyteServingsPerDay) { _, newValue in
            ElectrolyteTargetService.upsertToday(servingsPerDay: newValue, modelContext: modelContext)
        }
        .onChange(of: electrolyteAskEachTime) { _, _ in save() }
        .onChange(of: unitSystem) { oldValue, newValue in
            // Convert weight goal display when unit system changes
            if oldValue != newValue {
                if newValue == .imperial {
                    // metric -> imperial
                    weightGoalDisplay = weightGoalDisplay * 2.20462262
                } else {
                    // imperial -> metric
                    weightGoalDisplay = weightGoalDisplay / 2.20462262
                }
            }
            save()
        }
        .onChange(of: weightGoalDisplay) { _, _ in save() }
        .onChange(of: healthMonitoringStartDate) { _, _ in save() }
        .onChange(of: healthDataMaxPullDays) { _, _ in save() }
        .onChange(of: weekStartDay) { _, _ in save() }
    }

    private var currentTab: SectionTab {
        selectedTab ?? .dashboard
    }

    @ViewBuilder
    private func settingsDetail(tab: SectionTab) -> some View {
        Group {
            if tab == .notifications {
                // NotificationSettingsView has its own Form, so don't wrap it
                if let currentSettings = settings.first {
                    NotificationSettingsView(settings: currentSettings)
                } else {
                    Form {
                        Text("Loading settings...")
                    }
                }
            } else {
                Form {
                    switch tab {
                    case .dashboard:
                Section("Eating window") {
                    Button("Change eating window") {
                        isPickingSchedule = true
                    }
                }
                
                Section("Log Meal button") {
                    Toggle("Always show Log Meal", isOn: $alwaysShowLogMeal)

                    if !alwaysShowLogMeal {
                        LabeledContent("Show before window", value: hoursText(beforeHours))
                        Slider(value: $beforeHours, in: 0...6, step: 0.5)

                        LabeledContent("Show after window", value: hoursText(afterHours))
                        Slider(value: $afterHours, in: 0...6, step: 0.5)
                    }
                }

                Section("Meal list") {
                    Stepper(value: $dashboardMealListCount, in: 0...20) {
                        Text(dashboardMealListCount == 0 ? "Hide dashboard meal list" : "Show last \(dashboardMealListCount) meals")
                    }
                }

            case .meals:
                Section("Meal time display") {
                    Picker("Display meal times in", selection: $mealTimeDisplayMode) {
                        Text("Captured timezone").tag(MealTimeDisplayMode.captured)
                        Text("Device timezone").tag(MealTimeDisplayMode.device)
                    }

                    Text(exampleText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Units") {
                    Picker("Preferred units", selection: $unitSystem) {
                        Text("Metric").tag(UnitSystem.metric)
                        Text("Imperial").tag(UnitSystem.imperial)
                    }
                }

            case .electrolytes:
                Section("Daily target") {
                    Stepper(value: $electrolyteServingsPerDay, in: 0...12) {
                        Text(electrolyteServingsPerDay == 0 ? "Off" : "\(electrolyteServingsPerDay) servings per day")
                    }

                    Text("Changing this only affects today and future days.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Selection") {
                    Toggle("Ask me each time", isOn: $electrolyteAskEachTime)
                    Text("If enabled, ticking a serving will always ask which electrolyte you had.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Electrolyte templates") {
                    let electrolyteTemplates = templates.filter { $0.kind == MealTemplateKind.electrolyte.rawValue }

                    if electrolyteTemplates.isEmpty {
                        Text("No electrolyte templates yet. Create one in Meals and enable ‘Use as electrolyte’. ")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(electrolyteTemplates) { t in
                            Button {
                                toggleElectrolyteTemplate(t)
                            } label: {
                                HStack {
                                    Text(t.name)
                                    Spacer()
                                    if isElectrolyteTemplateSelected(t) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Selected templates are offered when you tick off a serving.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            case .notifications:
                // Never reached - handled in if statement above
                EmptyView()
                
            case .health:
                Section("Weight goal") {
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("Weight goal", value: $weightGoalDisplay, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(unitSystem == .metric ? "kg" : "lb")
                            .foregroundStyle(.secondary)
                    }
                    
                    if weightGoalDisplay == 0 {
                        Text("Set your weight goal to optimize the dashboard chart view")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Health monitoring") {
                    DatePicker("Journey start date", selection: $healthMonitoringStartDate, displayedComponents: .date)
                    
                    Text("Only health data from this date onwards will be shown")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Picker("Max data to pull", selection: $healthDataMaxPullDays) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                        Text("180 days").tag(180)
                        Text("1 year").tag(365)
                    }
                    
                    Text("Limits how far back to query HealthKit for performance")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Picker("Week start day", selection: $weekStartDay) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Text(day.displayName).tag(day)
                        }
                    }
                    
                    Text("If doing multi-day fasts, set this to the day you eat to best show the grouping of data for the week")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple Health") {
                    switch health.permission {
                    case .notAvailable:
                        Text("Health data isn’t available on this device.")
                            .foregroundStyle(.secondary)

                    case .notDetermined:
                        Button("Connect to Apple Health") {
                            Task { await health.requestAccess() }
                        }

                        Text(health.isDisconnected ? "Disconnected in-app." : "Not connected yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                    case .denied:
                        Text("Access is denied. Enable it in Settings → Health → Data Access & Devices.")
                            .foregroundStyle(.secondary)

                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }

                    case .authorized:
                        Text("Connected (read-only).")
                            .foregroundStyle(.secondary)
                    }

                    if let msg = health.errorMessage {
                        Text(msg)
                            .foregroundStyle(.secondary)
                    }
                }

                if health.permission == .authorized {
                    Section("Cached data") {
                        LabeledContent("Last updated", value: health.cacheUpdatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                        LabeledContent("Weight samples", value: "\(health.allWeights.count)")
                        LabeledContent("Sleep nights", value: "\(health.allSleepNights.count)")
                        
                        Text("Shows all cached health data up to the configured max days")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button("Refresh from Apple Health") {
                            Task { 
                                isRefreshingHealth = true
                                await health.refresh(
                                    maxDays: healthDataMaxPullDays,
                                    startDate: healthMonitoringStartDate,
                                    minDisplayTime: 1.0
                                )
                                isRefreshingHealth = false
                            }
                        }
                        .disabled(isRefreshingHealth)
                        
                        if isRefreshingHealth {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("Refreshing...")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Clear cached data", role: .destructive) {
                            health.clearCachedData()
                        }

                        Button("Disconnect Apple Health", role: .destructive) {
                            health.disconnect()
                        }

                        Text("Disconnecting here stops the app from reading Apple Health and clears local cached data. You can also revoke access in iOS Settings → Health.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            
            case .data:
                Section("iCloud Sync") {
                    HStack {
                        Label("Status", systemImage: syncStatusIcon)
                            .foregroundStyle(syncStatusColor)
                        Spacer()
                        Text(cloudKitSync.syncStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        cloudKitSync.requestSync(modelContext: modelContext)
                    } label: {
                        HStack {
                            Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
                            if cloudKitSync.isSyncing {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(!cloudKitSync.isOnline || cloudKitSync.isSyncing)
                    
                    Text("Data automatically syncs via iCloud when you're signed in and online. Note: TestFlight and production builds use separate CloudKit environments and do not sync with each other.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("Backup & Restore") {
                    Toggle("Include health data", isOn: $includeHealthDataInExport)
                    
                    Text("When enabled, exports will include cached HealthKit data (weights, body fat, sleep).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Label("Export all data", systemImage: "square.and.arrow.up")
                            if isExporting {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(isExporting)
                    
                    Text("Creates a JSON backup file of all your data that you can save to iCloud Drive, Files, or share with other devices.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Label("Import data", systemImage: "square.and.arrow.down")
                            if isImporting {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(isImporting)
                    
                    Text("Import a previously exported backup file. This will replace all existing data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            }
        }
        }
        .navigationTitle(tab.rawValue)
        .safeAreaInset(edge: .bottom) {
            versionFooter
        }
        .task {
            if tab == .health {
                await health.refreshPermissionOnly()
            } else if tab == .data {
                // Trigger initial sync check when viewing data tab
                cloudKitSync.requestSyncIfStale(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showingExportShare) {
            if let data = exportedData {
                ShareSheet(items: [data], filename: DataExportImportService.generateExportFilename())
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .alert("Import Data", isPresented: $showingImportConfirmation) {
            Button("Cancel", role: .cancel) {
                importedData = nil
            }
            Button("Import", role: .destructive) {
                performImport()
            }
        } message: {
            Text("This will replace all existing data with the imported backup. This action cannot be undone. Make sure to export your current data first if you want to keep it.")
        }
        .alert("Import Complete", isPresented: $showingImportResult) {
            Button("OK") {
                importResult = nil
                importError = nil
            }
        } message: {
            if let error = importError {
                Text("Import failed: \(error.localizedDescription)")
            } else if let result = importResult {
                Text(result.summary)
            }
        }
        .sheet(isPresented: $isPickingSchedule) {
            SchedulePickerView()
        }
    }

    private func save() {
        let current = settings.first ?? AppSettings()
        if settings.isEmpty { modelContext.insert(current) }

        current.alwaysShowLogMealButton = alwaysShowLogMeal
        current.logMealShowBeforeHours = beforeHours
        current.logMealShowAfterHours = afterHours

        current.dashboardMealListCount = dashboardMealListCount

        current.mealTimeDisplayMode = mealTimeDisplayMode.rawValue
        // current.mealTimeZoneBadgeStyle not user-configurable (single supported style)
        // current.mealTimeOffsetStyle removed

        current.electrolyteSelectionMode = electrolyteAskEachTime ? "askEachTime" : "fixed"

        current.unitSystem = unitSystem.rawValue

        // Convert weight goal display to kg for storage
        let weightGoalKg = unitSystem == .metric ? weightGoalDisplay : weightGoalDisplay / 2.20462262
        current.weightGoalKg = weightGoalKg > 0 ? weightGoalKg : nil
        current.healthMonitoringStartDate = healthMonitoringStartDate
        current.healthDataMaxPullDays = healthDataMaxPullDays
        current.weekStartDay = weekStartDay.rawValue

        modelContext.saveLogged()
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let data = try DataExportImportService.exportAllData(
                    modelContext: modelContext,
                    includeHealthData: includeHealthDataInExport,
                    healthKitViewModel: includeHealthDataInExport ? health : nil
                )
                await MainActor.run {
                    exportedData = data
                    showingExportShare = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                }
                // TODO: Show error alert
            }
        }
    }
    
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // For security-scoped resources, we need to access them
            let needsSecurityScope = url.startAccessingSecurityScopedResource()
            
            defer {
                if needsSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Use NSFileCoordinator for more reliable file access (especially for iCloud files)
                let coordinator = NSFileCoordinator()
                var coordinationError: NSError?
                var fileData: Data?
                var readError: Error?
                
                coordinator.coordinate(readingItemAt: url, options: [.withoutChanges], error: &coordinationError) { coordinatedURL in
                    do {
                        fileData = try Data(contentsOf: coordinatedURL)
                    } catch {
                        readError = error
                    }
                }
                
                // Check for errors
                if let error = coordinationError ?? readError {
                    throw error
                }
                
                guard let data = fileData else {
                    throw NSError(domain: "HardPhaseTracker", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Unable to read the file."
                    ])
                }
                
                // Validate it's valid JSON before showing confirmation
                _ = try JSONSerialization.jsonObject(with: data)
                
                importedData = data
                showingImportConfirmation = true
            } catch let error as NSError {
                // Provide more detailed error messages
                if error.domain == NSCocoaErrorDomain {
                    switch error.code {
                    case 257, 260: // File read permission errors
                        importError = NSError(domain: "HardPhaseTracker", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Unable to read the file. Try these steps:\n1. Open Files app\n2. Find your backup file\n3. Long-press on it\n4. Tap 'Copy'\n5. Navigate to 'On My iPad' → HardPhase Tracker (if available) or Downloads\n6. Paste the file there\n7. Try importing again"
                        ])
                    case 258: // File doesn't exist
                        importError = NSError(domain: "HardPhaseTracker", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "The selected file could not be found. If it's in iCloud, make sure it's fully downloaded (check for the cloud icon)."
                        ])
                    default:
                        importError = NSError(domain: "HardPhaseTracker", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Unable to read the file: \(error.localizedDescription)"
                        ])
                    }
                } else {
                    importError = error
                }
                showingImportResult = true
            }
            
        case .failure(let error):
            importError = error
            showingImportResult = true
        }
    }
    
    private func performImport() {
        guard let data = importedData else { return }
        
        isImporting = true
        
        Task {
            do {
                let result = try DataExportImportService.importAllData(
                    from: data,
                    into: modelContext,
                    healthKitViewModel: health,
                    mergeStrategy: .replace
                )
                await MainActor.run {
                    importResult = result
                    importedData = nil
                    isImporting = false
                    showingImportResult = true
                }
            } catch {
                await MainActor.run {
                    importError = error
                    importedData = nil
                    isImporting = false
                    showingImportResult = true
                }
            }
        }
    }

    private var exampleText: String {
        // Example: captured tz differs from device tz
        let captured = TimeZone(secondsFromGMT: 10 * 3600)!.identifier
        let device = TimeZone(secondsFromGMT: -8 * 3600)!
        let date = Date(timeIntervalSince1970: 1_735_689_600) // stable sample

        return "Example: " + DateFormatting.formatMealTime(
            date: date,
            capturedTimeZoneIdentifier: captured,
            displayMode: mealTimeDisplayMode,
            badgeStyle: .abbrev,
            offsetStyle: .utc,
            deviceTimeZone: device
        )
    }

    private func toggleElectrolyteTemplate(_ template: MealTemplate) {
        let current = settings.first ?? AppSettings()
        if settings.isEmpty { modelContext.insert(current) }

        var list = current.electrolyteTemplates ?? []
        if let idx = list.firstIndex(where: { $0.persistentModelID == template.persistentModelID }) {
            list.remove(at: idx)
        } else {
            list.append(template)
        }
        current.electrolyteTemplates = list
        modelContext.saveLogged()
    }

    private func isElectrolyteTemplateSelected(_ template: MealTemplate) -> Bool {
        let current = settings.first
        return (current?.electrolyteTemplates ?? []).contains(where: { $0.persistentModelID == template.persistentModelID })
    }

    private func hoursText(_ hours: Double) -> String {
        if hours == 0 { return "Off" }
        if hours < 1 {
            return "\(Int(hours * 60)) minutes"
        }
        if hours == 1 { return "1 hour" }
        return String(format: "%.1f hours", hours)
    }
    
    private var syncStatusIcon: String {
        switch cloudKitSync.syncStatusColor {
        case .success: "checkmark.icloud"
        case .warning: "exclamationmark.icloud"
        case .error: "xmark.icloud"
        case .syncing: "arrow.triangle.2.circlepath.icloud"
        }
    }
    
    private var syncStatusColor: Color {
        switch cloudKitSync.syncStatusColor {
        case .success: .green
        case .warning: .orange
        case .error: .red
        case .syncing: .blue
        }
    }
    
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text(AppVersion.fullVersionString)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("© 2026 Gordon Beeming")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    SettingsView()
}
