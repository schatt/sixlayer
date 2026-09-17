//
//  PlatformMacOSOptimizationsLayer5Tests.swift
//  SixLayerFrameworkTests
//
//  macOS L5 window-toolbar and keyboard-focus chrome (#451).
//  Toolbar: `presentedWindowToolbarStyle(.unified)` — not Scene `windowToolbarStyle`.
//  Keyboard: SwiftUI `.focusable()` — NavigationStack keyboard-first product is L6 (#446).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform macOS Optimizations Layer 5")
struct PlatformMacOSOptimizationsLayer5Tests {

    @Test
    func macOSUsesUnifiedPresentedWindowToolbar() {
        #expect(platformMacOSWindowToolbarChrome(for: .macOS) == .unified)
    }

    @Test
    func nonMacOSLeavesWindowToolbarUnmodified() {
        for platform in [SixLayerPlatform.iOS, .tvOS, .watchOS, .visionOS] {
            #expect(
                platformMacOSWindowToolbarChrome(for: platform) == .unmodified,
                "\(platform) must not invent macOS window toolbar chrome"
            )
        }
    }

    #if os(macOS)
    @Test @MainActor
    func platformMacOSWindowToolbarWrapsRootOnMacOS() {
        let view = Text("toolbar-root").platformMacOSWindowToolbar_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "WindowToolbar")
    }
    #endif

    #if os(iOS)
    @Test @MainActor
    func platformMacOSWindowToolbarStubPreservesRootOnIOS() {
        let view = Text("toolbar-root").platformMacOSWindowToolbar_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif

    @Test
    func macOSUsesFocusableKeyboardFocus() {
        #expect(platformMacOSKeyboardFocusChrome(for: .macOS) == .focusable)
    }

    @Test
    func nonMacOSLeavesKeyboardFocusUnmodified() {
        for platform in [SixLayerPlatform.iOS, .tvOS, .watchOS, .visionOS] {
            #expect(
                platformMacOSKeyboardFocusChrome(for: platform) == .unmodified,
                "\(platform) must not invent macOS keyboard-focus chrome"
            )
        }
    }

    #if os(macOS)
    @Test @MainActor
    func platformMacOSKeyboardFocusWrapsRootOnMacOS() {
        let view = Text("focus-root").platformMacOSKeyboardFocus_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_FocusableModifier")
    }
    #endif

    #if os(iOS)
    @Test @MainActor
    func platformMacOSKeyboardFocusStubPreservesRootOnIOS() {
        let view = Text("focus-root").platformMacOSKeyboardFocus_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif
}
