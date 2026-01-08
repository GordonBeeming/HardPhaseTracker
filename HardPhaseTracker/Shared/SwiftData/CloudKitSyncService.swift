import Foundation
import SwiftData
import OSLog
import Network

/// Service to manage CloudKit sync behavior with SwiftData
@MainActor
final class CloudKitSyncService: ObservableObject {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "CloudKitSync")
    
    @Published private(set) var lastSyncAttempt: Date?
    @Published private(set) var isOnline: Bool = true
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.gordonbeeming.HardPhaseTracker.networkMonitor")
    
    private static let lastSyncKey = "cloudkit.lastSyncAttempt"
    
    init() {
        lastSyncAttempt = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
        startNetworkMonitoring()
    }
    
    /// Attempts to trigger CloudKit sync by touching the data store
    /// SwiftData will automatically sync when network is available
    func requestSync(modelContext: ModelContext) {
        guard isOnline else {
            Self.logger.info("Skipping sync request - device offline")
            return
        }
        
        Self.logger.info("Requesting CloudKit sync...")
        
        // SwiftData automatically syncs with CloudKit, but we can encourage it by:
        // 1. Doing a save (even if nothing changed) - this triggers sync check
        // 2. Fetching data (forces SwiftData to check for remote changes)
        
        do {
            // Save triggers CloudKit push
            try modelContext.save()
            
            // Fetch triggers CloudKit pull - fetch a small amount of data
            var descriptor = FetchDescriptor<AppSettings>()
            descriptor.fetchLimit = 1
            _ = try? modelContext.fetch(descriptor)
            
            lastSyncAttempt = Date()
            UserDefaults.standard.set(lastSyncAttempt, forKey: Self.lastSyncKey)
            
            Self.logger.info("Sync request completed")
        } catch {
            Self.logger.error("Sync request failed: \(error.localizedDescription)")
        }
    }
    
    /// Request sync only if it's been a while since last attempt
    func requestSyncIfStale(modelContext: ModelContext, staleAfterMinutes: Double = 5) {
        guard isOnline else { return }
        
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
