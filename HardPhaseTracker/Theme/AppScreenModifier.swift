import SwiftUI

struct AppScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(AppTheme.primary(colorScheme))
            .foregroundStyle(AppTheme.text(colorScheme))
            .background(AppTheme.background(colorScheme))
    }
}

extension View {
    func appScreen() -> some View {
        modifier(AppScreenModifier())
    }
}
