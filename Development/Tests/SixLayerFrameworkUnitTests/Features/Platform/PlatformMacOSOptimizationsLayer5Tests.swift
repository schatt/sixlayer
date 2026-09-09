//
//  PlatformMacOSOptimizationsLayer5Tests.swift
//  SixLayerFrameworkTests
//
//  macOS L5 window-toolbar chrome decision and host/stub identity (#451).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform macOS Optimizations Layer 5")
struct PlatformMacOSOptimizationsLayer5Tests {

    @Test
    func macOSUsesUnifiedWindowToolbar() {
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
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Toolbar")
    }
    #endif

    #if os(iOS)
    @Test @MainActor
    func platformMacOSWindowToolbarStubPreservesRootOnIOS() {
        let view = Text("toolbar-root").platformMacOSWindowToolbar_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif
}
