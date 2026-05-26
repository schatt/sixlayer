import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite struct PlatformContrastAccessibilityTests {
    @Test func readableSecondary_standard_returnsSecondary() {
        #expect(PlatformContrastAccessibility.readableSecondary(contrast: .standard) == Color.secondary)
    }

    @Test func readableSecondary_increased_returnsPrimary() {
        #expect(PlatformContrastAccessibility.readableSecondary(contrast: .increased) == Color.primary)
    }
}
