//
//  PlatformIOSHapticFeedbackTests.swift
//  SixLayerFrameworkTests
//
//  Executing coverage for `platformIOSHapticFeedback` / `IOSHapticStyle` (#423).
//  Does not assert Taptic Engine firing (not observable in unit tests).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform iOS haptic feedback")
struct PlatformIOSHapticFeedbackTests {

    // MARK: - IOSHapticStyle (iOS)

    #if os(iOS)
    /// All six styles must be distinct case names (enum is not `CaseIterable`).
    @Test
    func iosHapticStyleCasesAreDistinct() {
        // Explicit list — do not invent CaseIterable; production is six cases only (#423).
        let names = iosHapticStyleCaseNames
        #expect(
            Set(names).count == 6,
            "IOSHapticStyle must expose six distinct cases, got: \(names)"
        )
    }

    private var iosHapticStyleCaseNames: [String] {
        [
            String(describing: IOSHapticStyle.light),
            String(describing: IOSHapticStyle.medium),
            String(describing: IOSHapticStyle.heavy),
            String(describing: IOSHapticStyle.success),
            String(describing: IOSHapticStyle.warning),
            String(describing: IOSHapticStyle.error)
        ]
    }

    /// iOS path applies `.onChange` — subject type wraps `Text` with `_ValueActionModifier2`
    /// (locked from deliberate-red `got:`). Does not lock `AnyView`.
    @Test @MainActor
    func platformIOSHapticFeedbackWrapsRootOnIOS() {
        let view = Text("haptic-root").platformIOSHapticFeedback(style: .medium, onTrigger: true)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_ValueActionModifier2")
    }
    #endif

    // MARK: - Non-iOS stub (macOS unit)

    #if os(macOS)
    /// Stub returns `self`; subject type remains the original root (`Text`).
    @Test @MainActor
    func platformIOSHapticFeedbackStubPreservesRootOnMacOS() {
        let view = Text("haptic-root").platformIOSHapticFeedback()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif
}
