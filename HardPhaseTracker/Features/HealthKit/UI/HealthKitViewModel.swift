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
    @Published private(set) var sleepLast7Nights: [SleepNight] = []
    @Published private(set) var errorMessage: String?

    private let service: HealthKitService

    private struct CachePayload: Codable {
        var latestWeight: WeightSample?
        var latestBodyFat: BodyFatSample?
        var weightsLast7Days: [WeightSample]
        var sleepLast7Nights: [SleepNight]
        var updatedAt: Date
    }

    private static let cacheKey = "healthkit.cache.v1"
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

    func refresh() async {
        errorMessage = nil
        await refreshPermission()

        guard permission == .authorized else { return }

        do {
            async let w = service.fetchLatestWeight()
            async let bf = service.fetchLatestBodyFat()
            async let w7 = service.fetchWeightSamples(lastDays: 7)
            async let s7 = service.fetchSleepNights(lastN: 7)

            latestWeight = try await w
            latestBodyFat = try await bf
            weightsLast7Days = try await w7
            sleepLast7Nights = try await s7
            saveCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshIfCacheStale(maxAgeHours: Double = 12) async {
        await refreshPermission()
        guard permission == .authorized else { return }
        guard !isDisconnected else { return }

        let last = cachedUpdatedAt()
        let age = Date().timeIntervalSince(last)
        if weightsLast7Days.isEmpty || sleepLast7Nights.isEmpty || age > maxAgeHours * 3600 {
            await refresh()
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
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        guard let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return }

        latestWeight = payload.latestWeight
        latestBodyFat = payload.latestBodyFat
        weightsLast7Days = payload.weightsLast7Days
        sleepLast7Nights = payload.sleepLast7Nights
        cacheUpdatedAt = payload.updatedAt
    }

    private func saveCache() {
        let payload = CachePayload(
            latestWeight: latestWeight,
            latestBodyFat: latestBodyFat,
            weightsLast7Days: weightsLast7Days,
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

