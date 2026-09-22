//
//  KeyboardNavigationContainerFocusTests.swift
//  SixLayerFrameworkTests
//
//  Empty collections must not be container-focusable. macOS paints an accent
//  focus platter on a focusable collection root (#521).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Keyboard navigation container focus")
struct KeyboardNavigationContainerFocusTests {

    @Test @MainActor
    func keyboardNavigationContainerDoesNotApplyFocusable() {
        let view = slfKeyboardNavigationContainer(Text("collection"))
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #expect(
            !description.contains("_FocusableModifier"),
            "Keyboard navigation must not mark the container .focusable(), got: \(description)"
        )
    }
}
