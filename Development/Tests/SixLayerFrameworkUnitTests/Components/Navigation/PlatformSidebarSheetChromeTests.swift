//
//  PlatformSidebarSheetChromeTests.swift
//  SixLayerFrameworkTests
//
//  Pure L6 decision for sidebar-sheet navigation chrome (#447).
//  iOS wraps NavigationStack; macOS uses a small presentation frame; others pass through.
//

import Testing
@testable import SixLayerFramework

@Suite("Platform sidebar sheet chrome")
struct PlatformSidebarSheetChromeTests {

    @Test
    func iOSWrapsSidebarSheetInNavigationStack() {
        #expect(platformSidebarSheetChrome(for: .iOS) == .navigationStackWrapped)
    }

    @Test
    func macOSFramesSidebarSheetForPresentation() {
        #expect(platformSidebarSheetChrome(for: .macOS) == .presentationFramed)
    }

    @Test
    func secondaryPlatformsLeaveSidebarSheetUnmodified() {
        for platform in [SixLayerPlatform.tvOS, .watchOS, .visionOS] {
            #expect(
                platformSidebarSheetChrome(for: platform) == .unmodified,
                "\(platform) must not invent iOS/macOS sidebar-sheet chrome"
            )
        }
    }
}
