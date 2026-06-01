import Testing

/// Unit tests for `AccessibilityTestUtilities.identifierMatchesExpectedPattern` glob vs regex semantics.
@Suite("AccessibilityTestUtilities pattern matching")
struct AccessibilityTestUtilitiesPatternTests {
    
    @Test @MainActor
    func sixLayerStarUiMatchesButtonWithSuffix() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SixLayer.main.ui.test.Button",
                expectedPattern: "SixLayer.*ui"
            )
        )
    }
    
    @Test @MainActor
    func sixLayerStarUiMatchesElementView() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SixLayer.main.ui.element.View",
                expectedPattern: "SixLayer.*ui"
            )
        )
    }
    
    @Test @MainActor
    func layer1GlobMatchesElementInPath() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SixLayer.layer1.main.ui.element.View",
                expectedPattern: "SixLayer.layer1.*element.*"
            )
        )
    }
    
    @Test @MainActor
    func accessibilityEnhancedGlob() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SixLayer.main.element.accessibility-enhanced-vo",
                expectedPattern: "*.main.element.accessibility-enhanced-*"
            )
        )
    }
    
    @Test @MainActor
    func exactRegexAnchorsStillWork() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SaveButton",
                expectedPattern: "^SaveButton$"
            )
        )
        #expect(
            !AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SaveButtonExtra",
                expectedPattern: "^SaveButton$"
            )
        )
    }
    
    @Test @MainActor
    func literalWithoutStarIsExactMatch() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "manual-custom-id",
                expectedPattern: "manual-custom-id"
            )
        )
    }
    
    @Test @MainActor
    func namespaceNormalizationBridging() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "main.ui.test.Button",
                expectedPattern: "SixLayer.*ui"
            )
        )
    }

    /// Layer 4/5/6 tests still use `*.main.ui.element.*`; named modifiers emit `SixLayer.main.ui.<Component>.View`.
    @Test @MainActor
    func legacyLayerElementGlobMatchesViewWithoutElementSegment() {
        #expect(
            AccessibilityTestUtilities.identifierMatchesExpectedPattern(
                "SixLayer.main.ui.AlertButton.View",
                expectedPattern: "*.main.ui.element.*"
            )
        )
    }
}
