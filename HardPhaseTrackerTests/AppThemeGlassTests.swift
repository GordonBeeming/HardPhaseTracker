import SwiftUI
import UIKit
import Testing
@testable import HardPhaseTracker

struct AppThemeGlassTests {
    @Test func glassFillHasHigherOpacityInLightMode() async throws {
        let dark = UIColor(AppTheme.glassFill(.dark))
        let light = UIColor(AppTheme.glassFill(.light))

        #expect(alpha(of: light) > alpha(of: dark))
    }

    @Test func glassBackdropProvidesGradientRange() async throws {
        let darkTop = UIColor(AppTheme.glassBackdropTop(.dark))
        let darkBottom = UIColor(AppTheme.glassBackdropBottom(.dark))
        let lightTop = UIColor(AppTheme.glassBackdropTop(.light))
        let lightBottom = UIColor(AppTheme.glassBackdropBottom(.light))

        #expect(luminance(of: darkTop) > luminance(of: darkBottom))
        #expect(luminance(of: lightTop) > luminance(of: lightBottom))
    }

    private func alpha(of color: UIColor) -> CGFloat {
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return alpha
    }

    private func luminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (0.299 * red) + (0.587 * green) + (0.114 * blue)
    }
}
