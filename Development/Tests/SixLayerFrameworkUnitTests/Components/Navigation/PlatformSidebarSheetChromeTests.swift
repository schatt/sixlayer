//
//  PlatformSidebarSheetChromeTests.swift
//  SixLayerFrameworkTests
//
//  Pure decision mapping + host subject-type for sidebar-sheet / overlay chrome (#447).
//  L6 apply is compile-time `#if os` mirroring these decisions so Mirror types stay
//  platform-truthful (a ViewBuilder runtime switch encoded NavigationStack on non-iOS).
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
        case .presentationFramed:
            #expect(
                description.contains("_FlexFrameLayout"),
                "macOS sidebar-sheet chrome should apply presentation frame, got: \(description)"
            )
            #expect(
                !description.contains("NavigationStack"),
                "macOS sidebar-sheet chrome must not wrap NavigationStack, got: \(description)"
            )
        case .unmodified:
            #expect(
                !description.contains("NavigationStack"),
                "Secondary-platform sidebar-sheet chrome must not wrap NavigationStack, got: \(description)"
            )
        }
    }
}
