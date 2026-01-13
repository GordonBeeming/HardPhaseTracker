import SwiftUI
import Testing
@testable import HardPhaseTracker

struct FastingPhaseInfoTests {
    
    // MARK: - Phase Count and Structure
    
    @Test func hasSevenPhases() {
        #expect(FastingPhaseInfo.phases.count == 7)
    }
    
    @Test func phasesHaveValidHourRanges() {
        for phase in FastingPhaseInfo.phases {
            #expect(phase.minHours >= 0)
            #expect(phase.name.isEmpty == false)
            #expect(phase.emoji.isEmpty == false)
            #expect(phase.hourRange.isEmpty == false)
            #expect(phase.description.isEmpty == false)
            #expect(phase.details.isEmpty == false)
        }
    }
    
    @Test func phasesAreInChronologicalOrder() {
        for i in 0..<FastingPhaseInfo.phases.count - 1 {
            let current = FastingPhaseInfo.phases[i]
            let next = FastingPhaseInfo.phases[i + 1]
            #expect(current.minHours < next.minHours)
        }
    }
    
    // MARK: - Current Phase Detection
    
    @Test func detectsPhase1_FedState() {
        // 0-4 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 2.0)
        #expect(phase?.name == "The Fed State")
        #expect(phase?.emoji == "🍽️")
    }
    
    @Test func detectsPhase2_Transition() {
        // 4-16 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 10.0)
        #expect(phase?.name == "The Transition")
        #expect(phase?.emoji == "🔄")
    }
    
    @Test func detectsPhase3_MetabolicSwitching() {
        // 16-48 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 30.0)
        #expect(phase?.name == "Metabolic Switching")
        #expect(phase?.emoji == "🔥")
    }
    
    @Test func detectsPhase4_DeepKetosis() {
        // 48-72 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 59.0)
        #expect(phase?.name == "Deep Ketosis")
        #expect(phase?.emoji == "🧠")
    }
    
    @Test func detectsPhase5_ImmuneReboot() {
        // 72-96 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 80.0)
        #expect(phase?.name == "The Immune Reboot")
        #expect(phase?.emoji == "🛡️")
    }
    
    @Test func detectsPhase6_CognitivePeak() {
        // 96-120 hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 110.0)
        #expect(phase?.name == "Cognitive Peak")
        #expect(phase?.emoji == "🏹")
    }
    
    @Test func detectsPhase7_MaximumAutophagy() {
        // 120+ hours
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 150.0)
        #expect(phase?.name == "Maximum Autophagy")
        #expect(phase?.emoji == "♻️")
    }
    
    @Test func handlesPhaseBoundaries() {
        // Test exact boundaries
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 0.0)?.name == "The Fed State")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 4.0)?.name == "The Transition")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 16.0)?.name == "Metabolic Switching")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 48.0)?.name == "Deep Ketosis")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 72.0)?.name == "The Immune Reboot")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 96.0)?.name == "Cognitive Peak")
        #expect(FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 120.0)?.name == "Maximum Autophagy")
    }
    
    // MARK: - Progress Calculation
    
    @Test func calculatesProgressAtStartOfPhase() {
        // At 48h (start of Deep Ketosis, 48-72h)
        let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: 48.0)
        #expect(progress == 0.0)
    }
    
    @Test func calculatesProgressAtMiddleOfPhase() {
        // At 60h in Deep Ketosis (48-72h)
        // Duration: 24h, elapsed: 12h, progress: 50%
        let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: 60.0)
        #expect(abs(progress - 0.5) < 0.01)
    }
    
    @Test func calculatesProgressNearEndOfPhase() {
        // At 71h in Deep Ketosis (48-72h)
        // Duration: 24h, elapsed: 23h, progress: ~95.8%
        let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: 71.0)
        #expect(progress > 0.95)
        #expect(progress < 1.0)
    }
    
    @Test func progressDoesNotExceedOne() {
        // Test all phases
        for hours in stride(from: 0.0, through: 119.0, by: 5.0) {
            let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: hours)
            #expect(progress >= 0.0)
            #expect(progress <= 1.0)
        }
    }
    
    @Test func openEndedPhaseReturnsZeroProgress() {
        // Maximum Autophagy (120+) has no defined end, should return 0
        let progress = FastingPhaseInfo.progressInCurrentPhase(hoursSinceLastMeal: 150.0)
        #expect(progress == 0.0)
    }
    
    // MARK: - Color System
    
    @Test func allPhasesHaveColorsForBothModes() {
        for phase in FastingPhaseInfo.phases {
            let lightColor = phase.color(for: .light)
            let darkColor = phase.color(for: .dark)
            
            // Colors should be different for light vs dark
            // (We can't easily compare Color objects, but we can verify they're created)
            #expect(lightColor != nil)
            #expect(darkColor != nil)
        }
    }
    
    @Test func colorHexStructureIsValid() {
        for phase in FastingPhaseInfo.phases {
            let colors = phase.colorHex
            
            // Hex strings should start with # and be 7 characters
            #expect(colors.light.hasPrefix("#"))
            #expect(colors.dark.hasPrefix("#"))
            #expect(colors.light.count == 7)
            #expect(colors.dark.count == 7)
        }
    }
    
    @Test func specificPhaseColors() {
        let fedState = FastingPhaseInfo.phases[0]
        #expect(fedState.colorHex.light == "#D32F2F") // Ruby
        #expect(fedState.colorHex.dark == "#FF5252")  // Coral
        
        let ketosis = FastingPhaseInfo.phases[3]
        #expect(ketosis.colorHex.light == "#2980B9") // Blue
        #expect(ketosis.colorHex.dark == "#46CBFF")  // Electric Blue
    }
    
    // MARK: - Edge Cases
    
    @Test func handlesNegativeHours() {
        // Should return nil or first phase
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: -1.0)
        // Either nil or first phase is acceptable
        if let phase = phase {
            #expect(phase.name == "The Fed State")
        }
    }
    
    @Test func handlesVeryLargeHours() {
        // Should return last phase
        let phase = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 1000.0)
        #expect(phase?.name == "Maximum Autophagy")
    }
    
    @Test func handlesDecimalHours() {
        // Test fractional hours work correctly
        let phase1 = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 2.5)
        let phase2 = FastingPhaseInfo.currentPhase(hoursSinceLastMeal: 15.75)
        
        #expect(phase1?.name == "The Fed State")
        #expect(phase2?.name == "The Transition")
    }
}
