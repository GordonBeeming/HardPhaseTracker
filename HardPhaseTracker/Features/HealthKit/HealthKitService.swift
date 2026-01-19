import Foundation
import HealthKit

final class HealthKitService {
    private let store: HKHealthStore

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private static let hasRequestedKey = "healthkit.hasRequestedAuthorization"

    var hasRequestedAuthorization: Bool {
        UserDefaults.standard.bool(forKey: Self.hasRequestedKey)
    }

    func authorizationRequestStatus() async -> HKAuthorizationRequestStatus {
        guard isAvailable else { return .unknown }

        let readTypes: Set<HKObjectType> = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
        ].compactMap { $0 as HKObjectType? })

        return await withCheckedContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { status, _ in
                continuation.resume(returning: status)
            }
        }
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = Set([
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
        ].compactMap { $0 as HKObjectType? })

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { _, error in
                UserDefaults.standard.set(true, forKey: Self.hasRequestedKey)

                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func fetchLatestWeight() async throws -> WeightSample? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sample = (samples?.first as? HKQuantitySample).map(HealthKitQuerySupport.mapWeight)
                continuation.resume(returning: sample)
            }
            store.execute(query)
        }
    }

    func fetchLatestBodyFat() async throws -> BodyFatSample? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sample = (samples?.first as? HKQuantitySample).map(HealthKitQuerySupport.mapBodyFat)
                continuation.resume(returning: sample)
            }
            store.execute(query)
        }
    }

    func fetchBodyFatSamples(lastDays days: Int, startDate: Date? = nil) async throws -> [BodyFatSample] {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else { return [] }
        
        // Calculate effective start date (respect both lastDays and monitoring start date).
        let daysStart = HealthKitQuerySupport.startDateForLastDays(days)
        let effectiveStart = startDate.map { max($0, daysStart) } ?? daysStart
        
        let predicate = HKQuery.predicateForSamples(withStart: effectiveStart, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let mapped = (samples as? [HKQuantitySample])?.map(HealthKitQuerySupport.mapBodyFat) ?? []
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    func fetchWeightSamples(lastDays days: Int, startDate: Date? = nil) async throws -> [WeightSample] {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return [] }
        
        // Calculate effective start date (respect both lastDays and monitoring start date).
        let daysStart = HealthKitQuerySupport.startDateForLastDays(days)
        let effectiveStart = startDate.map { max($0, daysStart) } ?? daysStart
        
        let predicate = HKQuery.predicateForSamples(withStart: effectiveStart, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let mapped = (samples as? [HKQuantitySample])?.map(HealthKitQuerySupport.mapWeight) ?? []
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }

    func fetchFirstWeight(afterDate: Date? = nil) async throws -> WeightSample? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        
        let predicate = afterDate.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: []) }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sample = (samples?.first as? HKQuantitySample).map(HealthKitQuerySupport.mapWeight)
                continuation.resume(returning: sample)
            }
            store.execute(query)
        }
    }

    func fetchSleepNights(lastN nights: Int) async throws -> [SleepNight] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }

        // Pull a bit more than we need and aggregate locally.
        let start = HealthKitQuerySupport.startDateForLastDays(max(14, nights * 2))
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let cats = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: HealthKitQuerySupport.aggregateSleepNights(samples: cats, nights: nights))
            }
            store.execute(query)
        }
    }
}
