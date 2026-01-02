import SwiftUI
import Testing

struct AppThemeTests {
    @Test func paletteMatchesSpec() async throws {
        #expect(AppTheme.Hex.lightBackground == 0xF8F9FA)
        #expect(AppTheme.Hex.lightText == 0x1A1A1A)
        #expect(AppTheme.Hex.lightPrimary == 0x0063B2)
        #expect(AppTheme.Hex.lightAccent == 0x46CBFF)
        #expect(AppTheme.Hex.lightDivider == 0xE9ECEF)

        #expect(AppTheme.Hex.darkBackground == 0x1A1A1A)
        #expect(AppTheme.Hex.darkText == 0xE0E0E0)
        #expect(AppTheme.Hex.darkPrimary == 0x46CBFF)
        #expect(AppTheme.Hex.darkAccent == 0x0063B2)
        #expect(AppTheme.Hex.darkDivider == 0x2C2C2C)
    }
}
