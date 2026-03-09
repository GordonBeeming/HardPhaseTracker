import Foundation
import CoreData
import SwiftData
import OSLog
import Network

/// Service that monitors real CloudKit sync events from the underlying
/// NSPersistentCloudKitContainer that SwiftData uses internally.
@MainActor
final class CloudKitSyncService: ObservableObject {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "CloudKitSync")

    // MARK: - Published state

    @Published private(set) var lastImport: Date?
    @Published private(set) var lastExport: Date?
    @Published private(set) var isOnline: Bool = true
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var syncError: String?

    // MARK: - Private

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.gordonbeeming.HardPhaseTracker.networkMonitor")
    private var eventObserver: Any?

    private static let lastImportKey = "cloudkit.lastImport"
    private static let lastExportKey = "cloudkit.lastExport"

    // MARK: - Init

    init() {
        lastImport = UserDefaults.standard.object(forKey: Self.lastImportKey) as? Date
        lastExport = UserDefaults.standard.object(forKey: Self.lastExportKey) as? Date
        startNetworkMonitoring()
        startObservingCloudKitEvents()
    }

    // MARK: - Real CloudKit event monitoring

    /// Observes NSPersistentCloudKitContainer.eventChangedNotification which fires
    /// for every import, export, and setup event — even when using SwiftData.
    private func startObservingCloudKitEvents() {
        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }

            Task { @MainActor [weak self] in
                self?.handleCloudKitEvent(event)
            }
        }
    }

    private func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        let typeName: String
        switch event.type {
        case .import: typeName = "import"
        case .export: typeName = "export"
        case .setup:  typeName = "setup"
        @unknown default: typeName = "unknown"
        }

        if event.endDate != nil {
            // Event finished
            if let error = event.error {
                Self.logger.error("CloudKit \(typeName) failed: \(error.localizedDescription)")
                syncError = "\(typeName) failed: \(error.localizedDescription)"
            } else {
                Self.logger.info("CloudKit \(typeName) succeeded")
                syncError = nil

                let now = Date()
                switch event.type {
                case .import:
                    lastImport = now
                    UserDefaults.standard.set(now, forKey: Self.lastImportKey)
                case .export:
                    lastExport = now
                    UserDefaults.standard.set(now, forKey: Self.lastExportKey)
                case .setup:
                    break
                @unknown default:
                    break
                }
            }
            isSyncing = false
        } else {
            // Event started
            Self.logger.info("CloudKit \(typeName) started")
            isSyncing = true
            if syncError != nil {
                // Clear previous error when a new sync starts
                syncError = nil
            }
        }
    }

    // MARK: - Manual sync trigger

    /// Saves the model context to encourage SwiftData to push changes to CloudKit.
    /// The actual sync result will arrive via eventChangedNotification.
    func requestSync(modelContext: ModelContext) {
        guard isOnline else {
            Self.logger.info("Skipping sync request - device offline")
            syncError = "Device is offline"
            return
        }

        Self.logger.info("Saving context to trigger CloudKit sync…")
        do {
            try modelContext.save()
        } catch {
            Self.logger.error("Context save failed: \(error.localizedDescription)")
            syncError = "Save failed: \(error.localizedDescription)"
        }
    }

    /// Request sync only if it's been a while since last activity
    func requestSyncIfStale(modelContext: ModelContext, staleAfterMinutes: Double = 5) {
        guard isOnline else { return }

        let now = Date()
        let lastActivity = [lastImport, lastExport].compactMap { $0 }.max()
        if let last = lastActivity {
            let minutesAgo = now.timeIntervalSince(last) / 60
            if minutesAgo < staleAfterMinutes {
                Self.logger.debug("Sync recent (< \(staleAfterMinutes) min ago), skipping")
                return
            }
        }

        requestSync(modelContext: modelContext)
    }

    // MARK: - Status

    var syncStatusMessage: String {
        if !isOnline {
            return "Offline – sync paused"
        }

        if isSyncing {
            return "Syncing…"
        }

        if let error = syncError {
            return "Sync error: \(error)"
        }

        let lastActivity = [lastImport, lastExport].compactMap { $0 }.max()
        if let last = lastActivity {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: last, relativeTo: Date()))"
        }

        return "Waiting for first sync"
    }

    var syncStatusColor: SyncStatusColor {
        if !isOnline || syncError != nil {
            return .error
        }
        if isSyncing {
            return .syncing
        }
        return .success
    }

    enum SyncStatusColor {
        case success
        case warning
        case error
        case syncing
    }

    // MARK: - Network

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied {
                    Self.logger.info("Network came online")
                } else {
                    Self.logger.info("Network went offline")
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    deinit {
        networkMonitor.cancel()
        if let observer = eventObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
