import Foundation
import SwiftData
import OSLog
import Network

/// Service to manage CloudKit sync behavior with SwiftData
@MainActor
final class CloudKitSyncService: ObservableObject {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "CloudKitSync")
    
    @Published private(set) var lastSyncAttempt: Date?
    @Published private(set) var lastSuccessfulSync: Date?
    @Published private(set) var isOnline: Bool = true
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var syncError: String?
    @Published private(set) var hasPendingChanges: Bool = false
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.gordonbeeming.HardPhaseTracker.networkMonitor")
    
    private static let lastSyncKey = "cloudkit.lastSyncAttempt"
    private static let lastSuccessfulSyncKey = "cloudkit.lastSuccessfulSync"
    
    init() {
        lastSyncAttempt = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
        lastSuccessfulSync = UserDefaults.standard.object(forKey: Self.lastSuccessfulSyncKey) as? Date
        startNetworkMonitoring()
    }
    
    /// Attempts to trigger CloudKit sync by touching the data store
    /// SwiftData will automatically sync when network is available
    func requestSync(modelContext: ModelContext) {
        guard isOnline else {
            Self.logger.info("Skipping sync request - device offline")
            syncError = "Device is offline"
            return
        }
        
        guard !isSyncing else {
            Self.logger.info("Sync already in progress, skipping")
            return
        }
        
        Self.logger.info("Requesting CloudKit sync...")
        
        isSyncing = true
        syncError = nil
        
        // SwiftData automatically syncs with CloudKit, but we can encourage it by:
        // 1. Doing a save (even if nothing changed) - this triggers sync check
        // 2. Fetching data (forces SwiftData to check for remote changes)
        
        do {
            // Save triggers CloudKit push
            try modelContext.save()
            
            lastSyncAttempt = Date()
            lastSuccessfulSync = Date()
            UserDefaults.standard.set(lastSyncAttempt, forKey: Self.lastSyncKey)
            UserDefaults.standard.set(lastSuccessfulSync, forKey: Self.lastSuccessfulSyncKey)
            
            // Check if there are pending changes
            hasPendingChanges = modelContext.hasChanges
            
            Self.logger.info("Sync request completed successfully")
            isSyncing = false
        } catch {
            Self.logger.error("Sync request failed: \(error.localizedDescription)")
            syncError = error.localizedDescription
            isSyncing = false
        }
    }
    
    /// Request sync only if it's been a while since last attempt
    func requestSyncIfStale(modelContext: ModelContext, staleAfterMinutes: Double = 5) {
        guard isOnline else { return }
        guard !isSyncing else { return }
        
        let now = Date()
        if let last = lastSyncAttempt {
            let minutesAgo = now.timeIntervalSince(last) / 60
            if minutesAgo < staleAfterMinutes {
                Self.logger.debug("Sync recent (< \(staleAfterMinutes) min ago), skipping")
                return
            }
        }
        
        requestSync(modelContext: modelContext)
    }
    
    /// Computed property for user-friendly sync status
    var syncStatusMessage: String {
        if !isOnline {
            return "Offline - sync paused"
        }
        
        if isSyncing {
            return "Syncing..."
        }
        
        if let error = syncError {
            return "Sync error: \(error)"
        }
        
        if hasPendingChanges {
            return "Changes pending sync"
        }
        
        if let lastSync = lastSuccessfulSync {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        }
        
        return "Sync status unknown"
    }
    
    var syncStatusColor: SyncStatusColor {
        if !isOnline || syncError != nil {
            return .error
        }
        
        if isSyncing {
            return .syncing
        }
        
        if hasPendingChanges {
            return .warning
        }
        
        return .success
    }
    
    enum SyncStatusColor {
        case success
        case warning
        case error
        case syncing
    }
    
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
    }
}
