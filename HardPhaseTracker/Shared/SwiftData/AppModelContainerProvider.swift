import Foundation
import CoreData
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

    /// Forces CloudKit to register the complete schema (all record types, fields, and
    /// relationships). Without this, CloudKit uses Just-In-Time inference and may miss
    /// parts of the schema that haven't been exercised by writing data.
    /// Only called in DEBUG builds to avoid App Store review issues.
    private static func initializeCloudKitSchemaIfNeeded(
        schema: Schema,
        storeURL: URL,
        containerId: String
    ) {
        // Use a separate store file so we don't interfere with the SwiftData container's lock
        let schemaInitURL = storeURL.deletingLastPathComponent()
            .appendingPathComponent("cloudkit-schema-init.sqlite")

        do {
            let modelTypes: [any PersistentModel.Type] = [
                MealTemplate.self,
                MealComponent.self,
                MealLogEntry.self,
                ElectrolyteIntakeEntry.self,
                ElectrolyteTargetSetting.self,
                EatingWindowSchedule.self,
                EatingWindowOverride.self,
                AppSettings.self,
            ]

            guard let mom = NSManagedObjectModel.makeManagedObjectModel(for: modelTypes) else {
                logger.error("Failed to create NSManagedObjectModel for schema initialization")
                return
            }

            let desc = NSPersistentStoreDescription(url: schemaInitURL)
            desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: containerId
            )
            desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            let cdContainer = NSPersistentCloudKitContainer(name: "SchemaInit", managedObjectModel: mom)
            cdContainer.persistentStoreDescriptions = [desc]

            cdContainer.loadPersistentStores { _, error in
                if let error {
                    logger.error("Schema init: failed to load store: \(error.localizedDescription)")
                }
            }

            try cdContainer.initializeCloudKitSchema()
            logger.info("✅ CloudKit schema initialized successfully")

            // Clean up: remove the store so it doesn't hold file locks
            if let store = cdContainer.persistentStoreCoordinator.persistentStores.first {
                try cdContainer.persistentStoreCoordinator.remove(store)
            }

            // Remove the temporary files
            let fm = FileManager.default
            for suffix in ["", "-shm", "-wal"] {
                let fileURL = schemaInitURL.appendingPathExtension(suffix.isEmpty ? "" : String(suffix.dropFirst()))
                let path = suffix.isEmpty ? schemaInitURL.path : schemaInitURL.path + suffix
                if fm.fileExists(atPath: path) {
                    try? fm.removeItem(atPath: path)
                }
            }
        } catch {
            // Non-fatal: schema init is best-effort. The app still works without it,
            // but some fields/relationships may not sync until data is written.
            logger.error("Schema init failed (non-fatal): \(error.localizedDescription)")
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

                // In DEBUG builds, force-register the full schema with CloudKit so that
                // JIT inference doesn't miss fields or relationships that haven't been
                // exercised yet. This prevents "some data syncs, some doesn't" issues.
                #if DEBUG
                initializeCloudKitSchemaIfNeeded(
                    schema: schema,
                    storeURL: cloudStoreURL,
                    containerId: iCloudContainerId
                )
                #endif

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
