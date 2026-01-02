import Foundation
import Testing

struct FastingEngineTests {
    @Test func computesElapsedAndPhase() async throws {
        let lastMeal = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: 60 * 60 * 25) // 25h

        let elapsed = FastingEngine.elapsed(from: lastMeal, to: now)
        #expect(Int(elapsed) == 60 * 60 * 25)
        #expect(FastingEngine.phase(for: elapsed) == .twentyFourPlus)
    }
}
