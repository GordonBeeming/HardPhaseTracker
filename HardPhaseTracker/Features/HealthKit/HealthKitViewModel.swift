import Foundation
import Combine
import HealthKit

@MainActor
final class HealthKitViewModel: ObservableObject {
    enum PermissionState: Equatable {
        case notAvailable
        case notDetermined
        case denied
        case authorized
    }

    @Published private(set) var permission: PermissionState = .notDetermined
    @Published private(set) var latestWeight: WeightSample?
    @Published private(set) var latestBodyFat: BodyFatSample?
    @Published private(set) var allWeights: [WeightSample] = [] // All weights up to maxDays
    @Published private(set) var allBodyFat: [BodyFatSample] = [] // All body fat samples up to maxDays
    @Published private(set) var firstWeight: WeightSample?
    @Published private(set) var allSleepNights: [SleepNight] = [] // All sleep up to maxDays
    @Published private(set) var errorMessage: String?
    
    // Computed properties derived from allWeights and allSleepNights
    var weightsLast7Days: [WeightSample] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allWeights.filter { $0.date >= cutoff }
    }
    
    var weightsLast14Days: [WeightSample] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return allWeights.filter { $0.date >= cutoff }
    }
    
    var sleepLast7Nights: [SleepNight] {
        // Return the 7 most recent nights, already sorted descending by date
        return Array(allSleepNights.prefix(7))
    }

    private let service: HealthKitService

    private struct CachePayload: Codable {
        var latestWeight: WeightSample?
        var latestBodyFat: BodyFatSample?
        var allWeights: [WeightSample]? // Optional for migration
        var allBodyFat: [BodyFatSample]? // Optional for migration
        var firstWeight: WeightSample? // Optional for migration
        var allSleepNights: [SleepNight]? // Optional for migration
        var updatedAt: Date
    }

    private static let cacheKey = "healthkit.cache.v3" // Bumped version for allBodyFat field
    private static let disconnectedKey = "healthkit.userDisconnected"
    private static let healthDataImportedNotification = Notification.Name("HealthKitViewModel.healthDataImported")

    @Published private(set) var cacheUpdatedAt: Date?
    @Published private(set) var isDisconnected: Bool = false

    init(service: HealthKitService = HealthKitService()) {
        self.service = service
        isDisconnected = UserDefaults.standard.bool(forKey: Self.disconnectedKey)
        loadCache()
        Task { await refreshPermission() }
        
        // Listen for health data import notifications
        NotificationCenter.default.addObserver(
            forName: Self.healthDataImportedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadCache()
        }
    }

    func requestAccess() async {
        // Reconnect within the app (system-level Health permission is managed by iOS Settings).
        isDisconnected = false
        UserDefaults.standard.set(false, forKey: Self.disconnectedKey)

        errorMessage = nil
        do {
            try await service.requestAuthorization()
            await refreshPermission()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
            await refreshPermission()
        }
    }

    func refresh(maxDays: Int = 90, startDate: Date? = nil, minDisplayTime: TimeInterval = 0) async {
        let startTime = Date()
        errorMessage = nil
        await refreshPermission()

        guard permission == .authorized else { return }

        do {
            async let w = service.fetchLatestWeight()
            async let bf = service.fetchLatestBodyFat()
            async let wAll = service.fetchWeightSamples(lastDays: maxDays, startDate: startDate)
            async let bfAll = service.fetchBodyFatSamples(lastDays: maxDays, startDate: startDate)
            async let first = service.fetchFirstWeight(afterDate: startDate)
            async let sAll = service.fetchSleepNights(lastN: maxDays)

            let fetchedWeight = try await w
            let fetchedBodyFat = try await bf
            let fetchedWeights = try await wAll
            let fetchedBodyFats = try await bfAll
            let fetchedFirstWeight = try await first
            let fetchedSleep = try await sAll
            
            // Only update if we got data, otherwise preserve cached data
            // This prevents clearing data due to sync issues or permission problems
            if fetchedWeight != nil || !fetchedWeights.isEmpty {
                latestWeight = fetchedWeight
                allWeights = fetchedWeights
                firstWeight = fetchedFirstWeight
            }
            
            if fetchedBodyFat != nil || !fetchedBodyFats.isEmpty {
                latestBodyFat = fetchedBodyFat
                allBodyFat = fetchedBodyFats
            }
            
            if !fetchedSleep.isEmpty {
                allSleepNights = fetchedSleep
            }
            
            saveCache()
            
            // Ensure minimum display time
            if minDisplayTime > 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minDisplayTime {
                    try? await Task.sleep(nanoseconds: UInt64((minDisplayTime - elapsed) * 1_000_000_000))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func incrementalRefresh(maxDays: Int = 90, startDate: Date? = nil, minDisplayTime: TimeInterval = 0) async {
        let startTime = Date()
        errorMessage = nil
        await refreshPermission()

        guard permission == .authorized else { return }

        // Use the last cache update date as the incremental start date
        let incrementalStartDate = cacheUpdatedAt ?? startDate ?? Date().addingTimeInterval(-Double(maxDays) * 86400)

        do {
            // Fetch only new data since last refresh
            async let w = service.fetchLatestWeight()
            async let bf = service.fetchLatestBodyFat()
            async let newWeights = service.fetchWeightSamples(lastDays: maxDays, startDate: incrementalStartDate)
            async let newBodyFats = service.fetchBodyFatSamples(lastDays: maxDays, startDate: incrementalStartDate)
            async let first = service.fetchFirstWeight(afterDate: startDate)
            async let sAll = service.fetchSleepNights(lastN: maxDays)

            let fetchedWeight = try await w
            let fetchedBodyFat = try await bf
            let fetchedWeights = try await newWeights
            let fetchedBodyFats = try await newBodyFats
            let fetchedFirstWeight = try await first
            let fetchedSleep = try await sAll
            
            // Only update if we got data, otherwise preserve cached data
            if fetchedWeight != nil || !fetchedWeights.isEmpty {
                latestWeight = fetchedWeight
                
                // Merge new weights with existing cached weights
                let mergedWeights = mergeWeights(existing: allWeights, new: fetchedWeights)
                
                // Filter for all weights within maxDays
                let cutoffMaxDays = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
                allWeights = mergedWeights.filter { $0.date >= cutoffMaxDays }
                
                firstWeight = fetchedFirstWeight
            }
            
            if fetchedBodyFat != nil || !fetchedBodyFats.isEmpty {
                latestBodyFat = fetchedBodyFat
                
                // Merge new body fat samples with existing cached samples
                let mergedBodyFats = mergeBodyFats(existing: allBodyFat, new: fetchedBodyFats)
                
                // Filter for all body fat samples within maxDays
                let cutoffMaxDays = Calendar.current.date(byAdding: .day, value: -maxDays, to: Date()) ?? Date()
                allBodyFat = mergedBodyFats.filter { $0.date >= cutoffMaxDays }
            }
            
            if !fetchedSleep.isEmpty {
                allSleepNights = fetchedSleep
            }
            
            saveCache()
            
            // Ensure minimum display time
            if minDisplayTime > 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minDisplayTime {
                    try? await Task.sleep(nanoseconds: UInt64((minDisplayTime - elapsed) * 1_000_000_000))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func mergeWeights(existing: [WeightSample], new: [WeightSample]) -> [WeightSample] {
        // Create a dictionary of existing weights by date (truncated to day)
        var weightsByDay: [Date: WeightSample] = [:]
        
        let calendar = Calendar.current
        for weight in existing {
            let day = calendar.startOfDay(for: weight.date)
            weightsByDay[day] = weight
        }
        
        // Add/update with new weights
        for weight in new {
            let day = calendar.startOfDay(for: weight.date)
            // Keep the newer weight if there are multiple on the same day
            if let existingWeight = weightsByDay[day] {
                if weight.date > existingWeight.date {
                    weightsByDay[day] = weight
                }
            } else {
                weightsByDay[day] = weight
            }
        }
        
        // Return sorted array
        return weightsByDay.values.sorted { $0.date < $1.date }
    }
    
    private func mergeBodyFats(existing: [BodyFatSample], new: [BodyFatSample]) -> [BodyFatSample] {
        // Create a dictionary of existing body fat samples by date (truncated to day)
        var bodyFatsByDay: [Date: BodyFatSample] = [:]
        
        let calendar = Calendar.current
        for bodyFat in existing {
            let day = calendar.startOfDay(for: bodyFat.date)
            bodyFatsByDay[day] = bodyFat
        }
        
        // Add/update with new body fat samples
        for bodyFat in new {
            let day = calendar.startOfDay(for: bodyFat.date)
            // Keep the newer sample if there are multiple on the same day
            if let existingBodyFat = bodyFatsByDay[day] {
                if bodyFat.date > existingBodyFat.date {
                    bodyFatsByDay[day] = bodyFat
                }
            } else {
                bodyFatsByDay[day] = bodyFat
            }
        }
        
        // Return sorted array
        return bodyFatsByDay.values.sorted { $0.date < $1.date }
    }

    func refreshIfCacheStale(maxAgeHours: Double = 12, maxDays: Int = 90, startDate: Date? = nil) async {
        await refreshPermission()
        guard permission == .authorized else { return }
        guard !isDisconnected else { return }

        let last = cachedUpdatedAt()
        let age = Date().timeIntervalSince(last)
        if allWeights.isEmpty || allSleepNights.isEmpty || age > maxAgeHours * 3600 {
            await refresh(maxDays: maxDays, startDate: startDate)
        }
    }
    
    func refreshIfTodayWeightMissing(maxDays: Int = 90, startDate: Date? = nil) async {
        await refreshPermission()
        guard permission == .authorized else { return }
        guard !isDisconnected else { return }
        
        // Check if we have a weight sample from today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let hasTodayWeight = latestWeight.map { weight in
            calendar.isDate(weight.date, inSameDayAs: Date())
        } ?? false
        
        // If no weight for today, do an incremental refresh
        if !hasTodayWeight {
            await incrementalRefresh(maxDays: maxDays, startDate: startDate)
        } else {
            // Otherwise just do a stale check
            await refreshIfCacheStale(maxDays: maxDays, startDate: startDate)
        }
    }

    func refreshPermissionOnly() async {
        await refreshPermission()
    }

    func clearCachedData() {
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        cacheUpdatedAt = nil
        latestWeight = nil
        latestBodyFat = nil
        allWeights = []
        allBodyFat = []
        firstWeight = nil
        allSleepNights = []
    }

    func disconnect() {
        clearCachedData()
        isDisconnected = true
        UserDefaults.standard.set(true, forKey: Self.disconnectedKey)
        permission = .notDetermined
    }
    
    /// Restore health data from backup (for testing purposes)
    /// This updates the local cache without syncing to HealthKit
    func restoreHealthData(
        weights: [WeightSample]?,
        bodyFat: [BodyFatSample]?,
        sleepNights: [SleepNight]?
    ) {
        if let weights = weights {
            allWeights = weights
            firstWeight = weights.first
            latestWeight = weights.last
        }
        
        if let bodyFat = bodyFat {
            allBodyFat = bodyFat
            latestBodyFat = bodyFat.last
        }
        
        if let sleepNights = sleepNights {
            allSleepNights = sleepNights
        }
        
        saveCache()
        
        // Notify other HealthKitViewModel instances to reload from cache
        NotificationCenter.default.post(name: Self.healthDataImportedNotification, object: nil)
    }

    private func refreshPermission() async {
        guard service.isAvailable else {
            permission = .notAvailable
            return
        }

        if isDisconnected {
            permission = .notDetermined
            return
        }

        let status = await service.authorizationRequestStatus()

        switch status {
        case .unnecessary:
            permission = .authorized
        case .shouldRequest:
            permission = service.hasRequestedAuthorization ? .denied : .notDetermined
        case .unknown:
            permission = .notDetermined
        @unknown default:
            permission = .notDetermined
        }
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else {
            // Try loading old cache format (v1 or v2 with weightsLast7Days/14Days) and migrate
            if let oldData = UserDefaults.standard.data(forKey: "healthkit.cache.v1"),
               let oldPayload = try? JSONDecoder().decode(OldCachePayload.self, from: oldData) {
                // Migrate v1 cache to current format
                latestWeight = oldPayload.latestWeight
                latestBodyFat = oldPayload.latestBodyFat
                allWeights = oldPayload.weightsLast7Days // Use old 7 days data as starting point
                firstWeight = nil // Will be fetched on next refresh
                allSleepNights = oldPayload.sleepLast7Nights // Use old 7 nights data as starting point
                cacheUpdatedAt = oldPayload.updatedAt
                
                // Clear old cache
                UserDefaults.standard.removeObject(forKey: "healthkit.cache.v1")
            }
            return
        }
        
        guard let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return }

        latestWeight = payload.latestWeight
        latestBodyFat = payload.latestBodyFat
        allWeights = payload.allWeights ?? []
        allBodyFat = payload.allBodyFat ?? []
        firstWeight = payload.firstWeight
        allSleepNights = payload.allSleepNights ?? []
        cacheUpdatedAt = payload.updatedAt
    }

    // Old cache format for migration
    private struct OldCachePayload: Codable {
        var latestWeight: WeightSample?
        var latestBodyFat: BodyFatSample?
        var weightsLast7Days: [WeightSample]
        var sleepLast7Nights: [SleepNight]
        var updatedAt: Date
    }

    private func saveCache() {
        let payload = CachePayload(
            latestWeight: latestWeight,
            latestBodyFat: latestBodyFat,
            allWeights: allWeights,
            allBodyFat: allBodyFat,
            firstWeight: firstWeight,
            allSleepNights: allSleepNights,
            updatedAt: Date()
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
        cacheUpdatedAt = payload.updatedAt
    }

    private func cachedUpdatedAt() -> Date {
        cacheUpdatedAt ?? .distantPast
    }
}

