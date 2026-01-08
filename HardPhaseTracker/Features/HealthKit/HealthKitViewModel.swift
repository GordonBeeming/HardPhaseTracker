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
    @Published private(set) var weightsLast7Days: [WeightSample] = []
    @Published private(set) var weightsLast14Days: [WeightSample] = []
    @Published private(set) var firstWeight: WeightSample?
    @Published private(set) var sleepLast7Nights: [SleepNight] = []
    @Published private(set) var errorMessage: String?

    private let service: HealthKitService

    private struct CachePayload: Codable {
        var latestWeight: WeightSample?
        var latestBodyFat: BodyFatSample?
        var weightsLast7Days: [WeightSample]
        var weightsLast14Days: [WeightSample]? // Optional for migration
        var firstWeight: WeightSample? // Optional for migration
        var sleepLast7Nights: [SleepNight]
        var updatedAt: Date
    }

    private static let cacheKey = "healthkit.cache.v2" // Bumped version for new fields
    private static let disconnectedKey = "healthkit.userDisconnected"

    @Published private(set) var cacheUpdatedAt: Date?
    @Published private(set) var isDisconnected: Bool = false

    init(service: HealthKitService = HealthKitService()) {
        self.service = service
        isDisconnected = UserDefaults.standard.bool(forKey: Self.disconnectedKey)
        loadCache()
        Task { await refreshPermission() }
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

    func refresh(maxDays: Int = 90, startDate: Date? = nil) async {
        errorMessage = nil
        await refreshPermission()

        guard permission == .authorized else { return }

        do {
            async let w = service.fetchLatestWeight()
            async let bf = service.fetchLatestBodyFat()
            async let w7 = service.fetchWeightSamples(lastDays: min(7, maxDays), startDate: startDate)
            async let w14 = service.fetchWeightSamples(lastDays: min(14, maxDays), startDate: startDate)
            async let first = service.fetchFirstWeight(afterDate: startDate)
            async let s7 = service.fetchSleepNights(lastN: 7)

            latestWeight = try await w
            latestBodyFat = try await bf
            weightsLast7Days = try await w7
            weightsLast14Days = try await w14
            firstWeight = try await first
            sleepLast7Nights = try await s7
            saveCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshIfCacheStale(maxAgeHours: Double = 12, maxDays: Int = 90, startDate: Date? = nil) async {
        await refreshPermission()
        guard permission == .authorized else { return }
        guard !isDisconnected else { return }

        let last = cachedUpdatedAt()
        let age = Date().timeIntervalSince(last)
        if weightsLast7Days.isEmpty || weightsLast14Days.isEmpty || sleepLast7Nights.isEmpty || age > maxAgeHours * 3600 {
            await refresh(maxDays: maxDays, startDate: startDate)
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
        weightsLast7Days = []
        weightsLast14Days = []
        firstWeight = nil
        sleepLast7Nights = []
    }

    func disconnect() {
        clearCachedData()
        isDisconnected = true
        UserDefaults.standard.set(true, forKey: Self.disconnectedKey)
        permission = .notDetermined
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
            // Try loading old cache format (v1) and migrate
            if let oldData = UserDefaults.standard.data(forKey: "healthkit.cache.v1"),
               let oldPayload = try? JSONDecoder().decode(OldCachePayload.self, from: oldData) {
                // Migrate v1 cache to current format
                latestWeight = oldPayload.latestWeight
                latestBodyFat = oldPayload.latestBodyFat
                weightsLast7Days = oldPayload.weightsLast7Days
                weightsLast14Days = [] // Will be fetched on next refresh
                firstWeight = nil // Will be fetched on next refresh
                sleepLast7Nights = oldPayload.sleepLast7Nights
                cacheUpdatedAt = oldPayload.updatedAt
                
                // Clear old cache
                UserDefaults.standard.removeObject(forKey: "healthkit.cache.v1")
            }
            return
        }
        
        guard let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return }

        latestWeight = payload.latestWeight
        latestBodyFat = payload.latestBodyFat
        weightsLast7Days = payload.weightsLast7Days
        weightsLast14Days = payload.weightsLast14Days ?? []
        firstWeight = payload.firstWeight
        sleepLast7Nights = payload.sleepLast7Nights
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
            weightsLast7Days: weightsLast7Days,
            weightsLast14Days: weightsLast14Days,
            firstWeight: firstWeight,
            sleepLast7Nights: sleepLast7Nights,
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

