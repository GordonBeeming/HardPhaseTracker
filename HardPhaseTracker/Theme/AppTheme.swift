import SwiftUI

enum AppTheme {
    enum Hex {
        // Light
        static let lightBackground: UInt32 = 0xF8F9FA
        static let lightText: UInt32 = 0x1A1A1A
        static let lightPrimary: UInt32 = 0x0063B2
        static let lightAccent: UInt32 = 0x46CBFF
        static let lightDivider: UInt32 = 0xE9ECEF

        // Dark
        static let darkBackground: UInt32 = 0x1A1A1A
        static let darkText: UInt32 = 0xE0E0E0
        static let darkPrimary: UInt32 = 0x46CBFF
        static let darkAccent: UInt32 = 0x0063B2
        static let darkDivider: UInt32 = 0x2C2C2C
    }

    static func background(_ scheme: ColorScheme) -> Color {
        Color(.systemGroupedBackground)
    }

    static func glassBackdropTop(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return Color(hex: 0x0F172A)
        }
        return Color(hex: 0xF8FBFF)
    }

    static func glassBackdropBottom(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return Color(hex: 0x020617)
        }
        return Color(hex: 0xE8F4FF)
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        Color(.systemBackground)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? Hex.darkText : Hex.lightText)
    }

    static func primary(_ scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? Hex.darkPrimary : Hex.lightPrimary)
    }

    static func accent(_ scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? Hex.darkAccent : Hex.lightAccent)
    }

    static func divider(_ scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? Hex.darkDivider : Hex.lightDivider)
    }

    static func glassFill(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return .white.opacity(0.06)
        }
        return .white.opacity(0.56)
    }

    static func glassStroke(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return .white.opacity(0.16)
        }
        return .white.opacity(0.72)
    }

    static func glassShadow(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return .black.opacity(0.45)
        }
        return .black.opacity(0.12)
    }
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
