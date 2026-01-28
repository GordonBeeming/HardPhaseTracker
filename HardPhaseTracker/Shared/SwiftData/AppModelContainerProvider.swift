import Foundation
import OSLog
import SwiftData
import CloudKit

enum AppModelContainerProvider {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "SwiftData")
    
    /// Initialize the CloudKit zone if it doesn't exist
    /// This is called asynchronously to avoid blocking app startup
    private static func initializeCloudKitZone(containerId: String) {
        Task {
            do {
                let container = CKContainer(identifier: containerId)
                let database = container.privateCloudDatabase
                
                // Create the default zone used by SwiftData/CoreData
                let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
                let zone = CKRecordZone(zoneID: zoneID)
                
                logger.info("Creating CloudKit zone: \(zoneID.zoneName)")
                let _ = try await database.save(zone)
                logger.info("✅ CloudKit zone created successfully")
            } catch let error as CKError {
                // Zone already exists is not an error
                if error.code == .zoneNotFound || error.code == .partialFailure {
                    logger.info("CloudKit zone creation failed (expected if zone exists): \(error.localizedDescription)")
                } else {
                    logger.error("❌ Failed to create CloudKit zone: \(error.localizedDescription)")
                }
            } catch {
                logger.error("❌ Unexpected error creating CloudKit zone: \(error.localizedDescription)")
            }
        }
    }

    static func make(schema: Schema, iCloudContainerId: String) -> Result<ModelContainer, Error> {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

            // Keep CloudKit and local stores separate so a CloudKit toggle/issue doesn't break the local store.
            // Also use separate stores for Debug (Development) vs Release (Production) to prevent CloudKit conflicts
            #if DEBUG
            let cloudStoreURL = appSupport.appendingPathComponent("cloud-dev.store")
            let localStoreURL = appSupport.appendingPathComponent("default-dev.store")
            #else
            let cloudStoreURL = appSupport.appendingPathComponent("cloud.store")
            let localStoreURL = appSupport.appendingPathComponent("default.store")
            #endif

            // 1) Prefer CloudKit (private database)
            // Note: CloudKit is not reliably available in iOS Simulator
            #if targetEnvironment(simulator)
            logger.info("Running in simulator - skipping CloudKit, using local storage")
            #else
            do {
                logger.info("Attempting to create CloudKit container with ID: \(iCloudContainerId)")
                
                // Initialize CloudKit zone if needed
                initializeCloudKitZone(containerId: iCloudContainerId)
                
                let cloud = ModelConfiguration(
                    schema: schema,
                    url: cloudStoreURL,
                    cloudKitDatabase: .private(iCloudContainerId)
                )
                let container = try ModelContainer(for: schema, configurations: [cloud])
                logger.info("✅ CloudKit container created successfully")
                return .success(container)
            } catch {
                logger.error("❌ CloudKit SwiftData store failed; falling back to local-only store")
                logger.error("   Error: \(error.localizedDescription)")
                logger.error("   Error type: \(String(describing: type(of: error)))")
                if let nsError = error as NSError? {
                    logger.error("   Domain: \(nsError.domain), Code: \(nsError.code)")
                    logger.error("   User info: \(nsError.userInfo)")
                }
            }
            #endif

            // 2) Fallback to local store
            do {
                let local = ModelConfiguration(schema: schema, url: localStoreURL)
                return .success(try ModelContainer(for: schema, configurations: [local]))
            } catch {
                logger.error("Local SwiftData store failed: \(error.localizedDescription)")

                // 3) Recovery: start with a fresh local store (preserve the failing store file).
                // This avoids a hard-stop if the on-device store is corrupted. In production, a more
                // sophisticated migration strategy may be needed, but SwiftData doesn't yet offer
                // granular repair tooling.
                let recoveryStoreURL = appSupport.appendingPathComponent("default.recovery.store")

                do {
                    let recovery = ModelConfiguration(schema: schema, url: recoveryStoreURL)
                    logger.error("Starting fresh local store at \(recoveryStoreURL.path)")
                    return .success(try ModelContainer(for: schema, configurations: [recovery]))
                } catch {
                    logger.error("Recovery local SwiftData store failed: \(error.localizedDescription)")
                    return .failure(error)
                }
            }
        } catch {
            logger.error("SwiftData storage directory setup failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
