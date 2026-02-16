import SwiftUI

struct AppScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(AppTheme.primary(colorScheme))
            .foregroundStyle(AppTheme.text(colorScheme))
            .background {
                LinearGradient(
                    colors: [
                        AppTheme.glassBackdropTop(colorScheme),
                        AppTheme.glassBackdropBottom(colorScheme)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RadialGradient(
                        colors: [
                            AppTheme.accent(colorScheme).opacity(colorScheme == .dark ? 0.14 : 0.24),
                            .clear
                        ],
                        center: .topTrailing,
                        startRadius: 40,
                        endRadius: 380
                    )
                )
                .ignoresSafeArea()
            }
    }
}

extension View {
    func appScreen() -> some View {
        modifier(AppScreenModifier())
    }
}
