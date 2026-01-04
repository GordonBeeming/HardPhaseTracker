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

struct SleepNight: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let asleepSeconds: TimeInterval

    init(id: UUID = UUID(), date: Date, asleepSeconds: TimeInterval) {
        self.id = id
        self.date = date
        self.asleepSeconds = asleepSeconds
    }
}
