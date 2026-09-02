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
    /// Deliberate red: expect five unique names until production coverage is locked.
    @Test
    func iosHapticStyleCasesAreDistinct() {
        let names = [
            String(describing: IOSHapticStyle.light),
            String(describing: IOSHapticStyle.medium),
            String(describing: IOSHapticStyle.heavy),
            String(describing: IOSHapticStyle.success),
            String(describing: IOSHapticStyle.warning),
            String(describing: IOSHapticStyle.error)
        ]
        #expect(
            Set(names).count == 5,
            "IOSHapticStyle must expose six distinct cases, got: \(names)"
        )
    }

    /// iOS modifier wraps the root (`.onChange`); lock subject type from `got:` after red.
    @Test @MainActor
    func platformIOSHapticFeedbackWrapsRootOnIOS() {
        let view = Text("haptic-root").platformIOSHapticFeedback(style: .medium, onTrigger: true)
        BaseTestClass.expectViewSubjectTypeContains(
            view,
            rootViewName: "NotAHapticWrapper"
        )
    }
    #endif

    // MARK: - Non-iOS stub (macOS unit)

    #if os(macOS)
    /// Stub returns `self`; subject type must still contain the original root.
    /// Deliberate red: wrong root name until locked from `got:`.
    @Test @MainActor
    func platformIOSHapticFeedbackStubPreservesRootOnMacOS() {
        let view = Text("haptic-root").platformIOSHapticFeedback()
        BaseTestClass.expectViewSubjectTypeContains(
            view,
            rootViewName: "NotTheRootText"
        )
    }
    #endif
}
