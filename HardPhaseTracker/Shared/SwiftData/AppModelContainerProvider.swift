import Foundation
import OSLog
import SwiftData

enum AppModelContainerProvider {
    private static let logger = Logger(subsystem: "HardPhaseTracker", category: "SwiftData")

    static func make(schema: Schema, iCloudContainerId: String) -> Result<ModelContainer, Error> {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

            // Keep CloudKit and local stores separate so a CloudKit toggle/issue doesn't break the local store.
            let cloudStoreURL = appSupport.appendingPathComponent("cloud.store")
            let localStoreURL = appSupport.appendingPathComponent("default.store")

            // 1) Prefer CloudKit (private database)
            do {
                let cloud = ModelConfiguration(
                    schema: schema,
                    url: cloudStoreURL,
                    cloudKitDatabase: .private(iCloudContainerId)
                )
                return .success(try ModelContainer(for: schema, configurations: [cloud]))
            } catch {
                logger.error("CloudKit SwiftData store failed; falling back to local-only store: \(error.localizedDescription)")
            }

            // 2) Fallback to local store
            do {
                let local = ModelConfiguration(schema: schema, url: localStoreURL)
                return .success(try ModelContainer(for: schema, configurations: [local]))
            } catch {
                logger.error("Local SwiftData store failed: \(error.localizedDescription)")
                return .failure(error)
            }
        } catch {
            logger.error("SwiftData storage directory setup failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
