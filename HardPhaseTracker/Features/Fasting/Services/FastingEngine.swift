import Foundation

enum FastingEngine {
    static func elapsed(from lastMeal: Date, to now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(lastMeal))
    }

    static func phase(for elapsed: TimeInterval) -> FastingPhase {
        let hours = elapsed / 3600
        if hours >= 72 { return .seventyTwoPlus }
        if hours >= 48 { return .fortyEightPlus }
        if hours >= 24 { return .twentyFourPlus }
        return .underTwentyFour
    }
}
