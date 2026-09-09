//
//  PlatformMacOSOptimizationsLayer5Tests.swift
//  SixLayerFrameworkTests
//
//  macOS L5 toolbar-style chrome decision and host/stub identity (#451).
//  View-level `.toolbarStyle(.browser)` — not Scene `windowToolbarStyle`.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform macOS Optimizations Layer 5")
struct PlatformMacOSOptimizationsLayer5Tests {

    @Test
    func macOSUsesBrowserToolbarStyle() {
        #expect(platformMacOSToolbarChrome(for: .macOS) == .browser)
    }

    @Test
    func nonMacOSLeavesToolbarUnmodified() {
        for platform in [SixLayerPlatform.iOS, .tvOS, .watchOS, .visionOS] {
            #expect(
                platformMacOSToolbarChrome(for: platform) == .unmodified,
                "\(platform) must not invent macOS toolbar chrome"
            )
        }
    }

    #if os(macOS)
    @Test @MainActor
    func platformMacOSToolbarWrapsRootOnMacOS() {
        let view = Text("toolbar-root").platformMacOSToolbar_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "ToolbarStyle")
    }
    #endif

    #if os(iOS)
    @Test @MainActor
    func platformMacOSToolbarStubPreservesRootOnIOS() {
        let view = Text("toolbar-root").platformMacOSToolbar_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif
}
