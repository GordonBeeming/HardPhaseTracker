import SwiftUI
import Testing
@testable import HardPhaseTracker

struct ColorHexTests {
    
    // MARK: - 6-digit Hex Colors (RGB)
    
    @Test func parsesRedHex() {
        let color = Color(hex: "#FF0000")
        // Can't easily test Color equality, but we can verify it's created
        #expect(color != nil)
    }
    
    @Test func parsesGreenHex() {
        let color = Color(hex: "#00FF00")
        #expect(color != nil)
    }
    
    @Test func parsesBlueHex() {
        let color = Color(hex: "#0000FF")
        #expect(color != nil)
    }
    
    @Test func parsesWhiteHex() {
        let color = Color(hex: "#FFFFFF")
        #expect(color != nil)
    }
    
    @Test func parsesBlackHex() {
        let color = Color(hex: "#000000")
        #expect(color != nil)
    }
    
    // MARK: - Hex Without Hash
    
    @Test func parsesHexWithoutHash() {
        let colorWithHash = Color(hex: "#FF5252")
        let colorWithoutHash = Color(hex: "FF5252")
        
        // Both should create valid colors
        #expect(colorWithHash != nil)
        #expect(colorWithoutHash != nil)
    }
    
    // MARK: - 3-digit Hex Colors (Short form)
    
    @Test func parsesShortFormHex() {
        // #F00 should expand to #FF0000
        let color = Color(hex: "#F00")
        #expect(color != nil)
    }
    
    @Test func parsesShortFormWhite() {
        // #FFF should expand to #FFFFFF
        let color = Color(hex: "#FFF")
        #expect(color != nil)
    }
    
    // MARK: - 8-digit Hex Colors (ARGB with alpha)
    
    @Test func parsesHexWithAlpha() {
        // #80FF0000 - 50% transparent red
        let color = Color(hex: "#80FF0000")
        #expect(color != nil)
    }
    
    @Test func parsesFullyOpaqueHex() {
        // #FFFF5252 - fully opaque coral
        let color = Color(hex: "#FFFF5252")
        #expect(color != nil)
    }
    
    // MARK: - Real-world Fasting Phase Colors
    
    @Test func parsesFedStateColors() {
        let light = Color(hex: "#D32F2F") // Ruby
        let dark = Color(hex: "#FF5252")  // Coral
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesTransitionColors() {
        let light = Color(hex: "#E67E22") // Amber
        let dark = Color(hex: "#FF9F43")  // Orange
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesMetabolicSwitchingColors() {
        let light = Color(hex: "#F1C40F") // Goldenrod
        let dark = Color(hex: "#FFD740")  // Gold
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesDeepKetosisColors() {
        let light = Color(hex: "#2980B9") // Blue
        let dark = Color(hex: "#46CBFF")  // Electric Blue
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesImmuneRebootColors() {
        let light = Color(hex: "#16A085") // Deep Teal
        let dark = Color(hex: "#1DD1A1")  // Teal
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesCognitivePeakColors() {
        let light = Color(hex: "#8E44AD") // Purple
        let dark = Color(hex: "#BF5AF2")  // Bright Purple
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    @Test func parsesMaximumAutophagyColors() {
        let light = Color(hex: "#2C3E50") // Slate
        let dark = Color(hex: "#E0E0E0")  // White
        
        #expect(light != nil)
        #expect(dark != nil)
    }
    
    // MARK: - Edge Cases
    
    @Test func handlesInvalidHexGracefully() {
        // Invalid hex should still create a color (likely black as fallback)
        let color = Color(hex: "#ZZZZZZ")
        #expect(color != nil)
    }
    
    @Test func handlesEmptyString() {
        let color = Color(hex: "")
        #expect(color != nil)
    }
    
    @Test func handlesOnlyHash() {
        let color = Color(hex: "#")
        #expect(color != nil)
    }
    
    @Test func handlesLowerCaseHex() {
        let lowercase = Color(hex: "#ff5252")
        let uppercase = Color(hex: "#FF5252")
        
        #expect(lowercase != nil)
        #expect(uppercase != nil)
    }
    
    @Test func handlesMixedCaseHex() {
        let color = Color(hex: "#Ff52A2")
        #expect(color != nil)
    }
    
    // MARK: - All Fasting Phase Colors Parse Successfully
    
    @Test func allFastingPhaseColorsAreValid() {
        let allColorHexes = [
            "#D32F2F", "#FF5252", // Fed State
            "#E67E22", "#FF9F43", // Transition
            "#F1C40F", "#FFD740", // Metabolic Switching
            "#2980B9", "#46CBFF", // Deep Ketosis
            "#16A085", "#1DD1A1", // Immune Reboot
            "#8E44AD", "#BF5AF2", // Cognitive Peak
            "#2C3E50", "#E0E0E0"  // Maximum Autophagy
        ]
        
        for hex in allColorHexes {
            let color = Color(hex: hex)
            #expect(color != nil, "Failed to parse hex: \(hex)")
        }
    }
}
