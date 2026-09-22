//
//  KeyboardNavigationContainerFocusTests.swift
//  SixLayerFrameworkTests
//
//  Empty collections must not be container-focusable. macOS paints an accent
//  focus platter on a focusable collection root (#521).
//

import Testing
@testable import SixLayerFramework

@Suite("Keyboard navigation container focus")
struct KeyboardNavigationContainerFocusTests {

    @Test
    func keyboardCapableContainerStaysComplianceOnly() {
        #expect(
            slfKeyboardNavigationContainerChrome(hasKeyboardSupport: true) == .complianceOnly,
            "A keyboard-capable collection container must not be .focusable(); that platter is the off-center blue box"
        )
    }

    @Test
    func containerWithoutKeyboardSupportStaysComplianceOnly() {
        #expect(
            slfKeyboardNavigationContainerChrome(hasKeyboardSupport: false) == .complianceOnly
        )
    }
}
