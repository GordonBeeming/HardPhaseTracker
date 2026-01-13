import Foundation
import SwiftUI

struct FastingPhaseInfo {
    let name: String
    let emoji: String
    let hourRange: String
    let description: String
    let details: [String]
    let minHours: Double
    let maxHours: Double?
    
    struct PhaseColors {
        let light: String
        let dark: String
    }
    
    var colorHex: PhaseColors {
        switch name {
        case "The Fed State": 
            return PhaseColors(light: "#D32F2F", dark: "#FF5252") // Digestive Red
        case "The Transition": 
            return PhaseColors(light: "#E67E22", dark: "#FF9F43") // Glycogen Orange
        case "Metabolic Switching": 
            return PhaseColors(light: "#F1C40F", dark: "#FFD740") // Fat-Burning Gold
        case "Deep Ketosis": 
            return PhaseColors(light: "#2980B9", dark: "#46CBFF") // Ketone Blue
        case "The Immune Reboot": 
            return PhaseColors(light: "#16A085", dark: "#1DD1A1") // Healing Teal
        case "Cognitive Peak": 
            return PhaseColors(light: "#8E44AD", dark: "#BF5AF2") // Brain Power Purple
        case "Maximum Autophagy": 
            return PhaseColors(light: "#2C3E50", dark: "#E0E0E0") // The "Clean" Slate
        default: 
            return PhaseColors(light: "#808080", dark: "#808080") // Gray fallback
        }
    }
    
    func color(for colorScheme: ColorScheme) -> Color {
        let hex = colorScheme == .dark ? colorHex.dark : colorHex.light
        return Color(hex: hex)
    }
    
    static let phases: [FastingPhaseInfo] = [
        FastingPhaseInfo(
            name: "The Fed State",
            emoji: "🍽️",
            hourRange: "Hours 0–4",
            description: "Your body is in its \"default mode,\" running on the food you just ate.",
            details: [
                "What's Happening: Your digestive system is busy breaking down that meal into glucose, amino acids, and fatty acids. Insulin is spiked, and any extra energy is being packed away as glycogen (stored carbs) or fat.",
                "How You Feel: Usually satiated and comfortable. Depending on the meal, you might feel energized or a bit sluggish."
            ],
            minHours: 0,
            maxHours: 4
        ),
        FastingPhaseInfo(
            name: "The Transition",
            emoji: "🔄",
            hourRange: "Hours 4–16",
            description: "Your body is shifting gears from using the meal you just ate to dipping into stored energy.",
            details: [
                "What's Happening: Insulin drops, signaling that it's time to unlock those glycogen stores in your liver and muscles. As they deplete, your body ramps up the production of enzymes that break down fat.",
                "How You Feel: You might start feeling a bit hungry around the 12–16 hour mark, especially if you're not used to fasting. That's ghrelin (the hunger hormone) doing its job."
            ],
            minHours: 4,
            maxHours: 16
        ),
        FastingPhaseInfo(
            name: "Metabolic Switching",
            emoji: "🔥",
            hourRange: "Hours 16–48",
            description: "You've officially \"flipped the switch\" from a sugar-burner to a fat-burner.",
            details: [
                "What's Happening: Your liver starts cranking out ketones—a clean-burning fuel made from fat. These ketones are your brain's favorite alternative to glucose.",
                "How You Feel: Once you adapt, many people report mental clarity, stable energy, and a surprising lack of hunger."
            ],
            minHours: 16,
            maxHours: 48
        ),
        FastingPhaseInfo(
            name: "Deep Ketosis",
            emoji: "🧠",
            hourRange: "Hours 48–72",
            description: "This is where ketone levels peak, and your body is running like a well-oiled machine on fat.",
            details: [
                "What's Happening: Autophagy (cellular \"housekeeping\") kicks into high gear. Damaged proteins, old mitochondria, and other cellular junk are getting recycled.",
                "How You Feel: A sense of calm focus. Hunger can actually decrease because ketones suppress appetite."
            ],
            minHours: 48,
            maxHours: 72
        ),
        FastingPhaseInfo(
            name: "The Immune Reboot",
            emoji: "🛡️",
            hourRange: "Hours 72–96 (Sub-Stage A)",
            description: "Your immune system is getting a major overhaul.",
            details: [
                "What's Happening: Old, worn-out white blood cells are being broken down. When you refeed, your body will regenerate fresh, new immune cells—this is like hitting the \"reset\" button on your immune system.",
                "How You Feel: You might feel a bit more fatigued as resources are diverted toward cellular cleanup and regeneration."
            ],
            minHours: 72,
            maxHours: 96
        ),
        FastingPhaseInfo(
            name: "Cognitive Peak",
            emoji: "🏹",
            hourRange: "Hours 96–120 (Sub-Stage B)",
            description: "Brain-derived neurotrophic factor (BDNF) spikes, which is like fertilizer for your brain cells.",
            details: [
                "What's Happening: Your brain is producing new neurons and strengthening existing connections. Growth hormone (HGH) levels are also elevated, protecting muscle mass even in the absence of food.",
                "How You Feel: Many people report a profound sense of mental sharpness and emotional calm. It's like your brain has \"leveled up.\""
            ],
            minHours: 96,
            maxHours: 120
        ),
        FastingPhaseInfo(
            name: "Maximum Autophagy",
            emoji: "♻️",
            hourRange: "Hours 120+ (Sub-Stage C)",
            description: "This is the peak of cellular renewal and cleanup.",
            details: [
                "What's Happening: Your cells are operating at maximum efficiency for clearing out damaged components. Some studies suggest this is where the most profound anti-aging and disease-prevention benefits occur.",
                "How You Feel: Physically, you'll be weaker, but mentally, you might feel surprisingly clear. However, this is also the stage where electrolyte management becomes critical."
            ],
            minHours: 120,
            maxHours: nil
        )
    ]
    
    static let prosAndCons: [(title: String, items: [String], icon: String)] = [
        (
            title: "Benefits",
            items: [
                "Weight Loss: Extended fasting can accelerate fat loss, particularly if paired with consistent refeed protocols.",
                "Metabolic Health: Ketosis improves insulin sensitivity and metabolic flexibility.",
                "Cellular Renewal: Autophagy supports cellular repair and longevity.",
                "Mental Clarity: Ketones are neuroprotective and enhance focus."
            ],
            icon: "checkmark.circle.fill"
        ),
        (
            title: "Drawbacks",
            items: [
                "Social Impact: Multi-day fasts can be isolating, especially if meals are a big part of your social routine.",
                "Physical Performance: You'll have less explosive strength and endurance.",
                "Electrolyte Management: Without proper sodium, potassium, and magnesium, you can feel terrible.",
                "Risk of Disordered Eating: For some, extended fasting can trigger unhealthy behaviors around food."
            ],
            icon: "exclamationmark.triangle.fill"
        ),
        (
            title: "The Bottom Line",
            items: [
                "Fasting is a tool, not a cure-all. It can offer profound benefits, but it's not for everyone.",
                "If you're considering an extended fast (48+ hours), consult a doctor first, especially if you have underlying health conditions.",
                "Listen to your body. If you feel dizzy, weak, or unwell, break the fast.",
                "Always refeed responsibly. Start with light, easily digestible foods to avoid \"refeeding syndrome.\""
            ],
            icon: "lightbulb.fill"
        )
    ]
    
    static let medicalDisclaimer = """
This information is for educational purposes only and does not constitute medical advice. Fasting, especially extended fasting, can have serious health implications and is not suitable for everyone. Always consult with a qualified healthcare professional before starting any fasting regimen, particularly if you have any underlying health conditions, are taking medications, are pregnant or nursing, or have a history of eating disorders. Individual results may vary, and what works for one person may not be appropriate for another.
"""
    
    static func currentPhase(hoursSinceLastMeal: Double) -> FastingPhaseInfo? {
        return phases.first { phase in
            if let maxHours = phase.maxHours {
                return hoursSinceLastMeal >= phase.minHours && hoursSinceLastMeal < maxHours
            } else {
                return hoursSinceLastMeal >= phase.minHours
            }
        }
    }
    
    static func progressInCurrentPhase(hoursSinceLastMeal: Double) -> Double {
        guard let phase = currentPhase(hoursSinceLastMeal: hoursSinceLastMeal) else { return 0 }
        
        if let maxHours = phase.maxHours {
            let duration = maxHours - phase.minHours
            let elapsed = hoursSinceLastMeal - phase.minHours
            return min(1.0, max(0.0, elapsed / duration))
        } else {
            // For open-ended phases, return 0 to indicate no progress bar
            return 0
        }
    }
}
