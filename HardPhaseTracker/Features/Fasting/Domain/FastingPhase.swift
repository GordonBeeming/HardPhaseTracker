import SwiftUI

enum FastingPhase: Equatable {
    case underTwentyFour
    case twentyFourPlus
    case fortyEightPlus
    case seventyTwoPlus

    func color(using theme: AppTheme.Type, scheme: ColorScheme) -> Color {
        switch self {
        case .underTwentyFour:
            return theme.primary(scheme)
        case .twentyFourPlus:
            return theme.accent(scheme)
        case .fortyEightPlus:
            return theme.primary(scheme)
        case .seventyTwoPlus:
            return theme.accent(scheme)
        }
    }
}
