//
//  PlatformSidebarSheetChromeTests.swift
//  SixLayerFrameworkTests
//
//  Pure L6 decision for sidebar-sheet navigation chrome (#447).
//  iOS wraps NavigationStack; macOS uses a small presentation frame; others pass through.
//

import SwiftUI
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

    @Test
    func iOSAndMacOSWrapOverlayDetailInNavigationStack() {
        #expect(platformOverlayDetailChrome(for: .iOS) == .navigationStackWrapped)
        #expect(platformOverlayDetailChrome(for: .macOS) == .navigationStackWrapped)
    }

    @Test
    func secondaryPlatformsLeaveOverlayDetailUnmodified() {
        for platform in [SixLayerPlatform.tvOS, .watchOS, .visionOS] {
            #expect(
                platformOverlayDetailChrome(for: platform) == .unmodified,
                "\(platform) must not invent overlay-detail NavigationStack chrome"
            )
        }
    }

    @Test @MainActor
    func sidebarSheetChromeModifierMatchesHostDecision() {
        let view = Text("sidebar-sheet").platformSidebarSheetChrome_L6()
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        switch platformSidebarSheetChrome(for: .current) {
        case .navigationStackWrapped:
            #expect(
                description.contains("NavigationStack"),
                "iOS sidebar-sheet chrome should wrap NavigationStack, got: \(description)"
            )
        case .presentationFramed, .unmodified:
            #expect(
                !description.contains("NavigationStack"),
                "Non-iOS sidebar-sheet chrome must not wrap NavigationStack, got: \(description)"
            )
        }
    }
}
