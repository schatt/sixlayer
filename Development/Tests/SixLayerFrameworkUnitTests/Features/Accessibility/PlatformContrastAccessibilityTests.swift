import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite struct PlatformContrastAccessibilityTests {
    @Test func readableSecondary_standard_returnsSecondary() {
        #expect(PlatformContrastAccessibility.readableSecondary(contrast: .standard) == Color.secondary)
    }

    @Test func readableSecondary_increased_returnsPrimary() {
        let increased = PlatformContrastAccessibility.readableSecondary(contrast: .increased)
        let standard = PlatformContrastAccessibility.readableSecondary(contrast: .standard)
        #expect(increased == Color.primary)
        #expect(increased != standard, "Increase Contrast must not leave subtitle text at standard secondary strength")
    }
}
