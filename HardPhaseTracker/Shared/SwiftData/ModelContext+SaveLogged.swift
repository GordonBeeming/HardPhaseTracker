import Foundation
import OSLog
import SwiftData

extension ModelContext {
    func saveLogged(file: StaticString = #fileID, line: UInt = #line) {
        do {
            try save()
        } catch {
            Logger(subsystem: "HardPhaseTracker", category: "SwiftData")
                .error("SwiftData save failed (\(file):\(line)): \(error.localizedDescription)")
        }
    }
}
