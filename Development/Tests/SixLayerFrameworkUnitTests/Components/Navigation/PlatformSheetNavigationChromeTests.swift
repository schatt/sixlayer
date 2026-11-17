//
//  PlatformSheetNavigationChromeTests.swift
//  SixLayerFrameworkTests
//
//  Pure decision mapping + host subject-type for platformSheet NavigationStack
//  chrome (#636). Apply uses compile-time `#if os` so Mirror types stay
//  platform-truthful (same constraint as #447 sidebar/overlay chrome).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform sheet navigation chrome")
struct PlatformSheetNavigationChromeTests {

    @Test
    func iOSWrapsSheetContentInNavigationStack() {
        #expect(platformSheetNavigationChrome(for: .iOS) == .navigationStackWrapped)
    }

    @Test
    func macOSWrapsSheetContentInNavigationStack() {
        #expect(platformSheetNavigationChrome(for: .macOS) == .navigationStackWrapped)
    }

    @Test
    func secondaryPlatformsLeaveSheetContentUnmodified() {
        for platform in [SixLayerPlatform.tvOS, .watchOS, .visionOS] {
            #expect(
                platformSheetNavigationChrome(for: platform) == .unmodified,
                "\(platform) must not invent iOS/macOS sheet NavigationStack chrome"
            )
        }
    }

    /// Both-direction gate: pure `.current` decisions must match this binary's compile-time OS.
    @Test
    func currentPlatformDecisionMatchesCompileTimeOS() {
        #if os(iOS) || os(macOS)
        #expect(platformSheetNavigationChrome(for: .current) == .navigationStackWrapped)
        #else
        #expect(platformSheetNavigationChrome(for: .current) == .unmodified)
        #endif
    }

    @Test @MainActor
    func sheetNavigationChromeModifierMatchesHostDecision() {
        let view = Text("sheet-root").platformSheetNavigationChrome()
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        switch platformSheetNavigationChrome(for: .current) {
        case .navigationStackWrapped:
            #expect(
                description.contains("NavigationStack"),
                "iOS/macOS platformSheet chrome should wrap NavigationStack, got: \(description)"
            )
        case .unmodified:
            #expect(
                description == "Text",
                "Secondary-platform sheet chrome must be identity, got: \(description)"
            )
        }
    }
}
