import Foundation

struct WeightSample: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let kilograms: Double

    init(id: UUID = UUID(), date: Date, kilograms: Double) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
    }
}

struct BodyFatSample: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    /// Stored as 0...100 (percent)
    let percent: Double

    init(id: UUID = UUID(), date: Date, percent: Double) {
        self.id = id
        self.date = date
        self.percent = percent
    }
}

struct MuscleMassSample: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let kilograms: Double

    init(id: UUID = UUID(), date: Date, kilograms: Double) {
        self.id = id
        self.date = date
        self.kilograms = kilograms
    }
}

struct SleepNight: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let asleepSeconds: TimeInterval
    let inBedSeconds: TimeInterval

    init(id: UUID = UUID(), date: Date, asleepSeconds: TimeInterval, inBedSeconds: TimeInterval = 0) {
        self.id = id
        self.date = date
        self.asleepSeconds = asleepSeconds
        self.inBedSeconds = inBedSeconds
    }
}
