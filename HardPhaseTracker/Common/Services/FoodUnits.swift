import Foundation

enum UnitSystem: String {
    case metric
    case imperial
}

enum FoodUnit: String, CaseIterable, Identifiable {
    case g
    case kg
    case oz
    case lb
    case ml
    case l
    case flOz = "fl_oz"
    case cup
    case tbsp
    case tsp
    case piece

    var id: String { rawValue }

    var label: String {
        switch self {
        case .g: return "g"
        case .kg: return "kg"
        case .oz: return "oz"
        case .lb: return "lb"
        case .ml: return "ml"
        case .l: return "L"
        case .flOz: return "fl oz"
        case .cup: return "cup"
        case .tbsp: return "tbsp"
        case .tsp: return "tsp"
        case .piece: return "piece"
        }
    }

    static func ordered(for system: UnitSystem) -> [FoodUnit] {
        switch system {
        case .metric:
            return [.g, .kg, .ml, .l, .oz, .lb, .flOz, .cup, .tbsp, .tsp, .piece]
        case .imperial:
            return [.oz, .lb, .flOz, .cup, .tbsp, .tsp, .g, .kg, .ml, .l, .piece]
        }
    }

    static func defaultUnit(for system: UnitSystem) -> FoodUnit {
        switch system {
        case .metric: return .g
        case .imperial: return .oz
        }
    }
}

extension AppSettings {
    var unitSystemEnum: UnitSystem {
        UnitSystem(rawValue: unitSystem ?? "") ?? .metric
    }
}
