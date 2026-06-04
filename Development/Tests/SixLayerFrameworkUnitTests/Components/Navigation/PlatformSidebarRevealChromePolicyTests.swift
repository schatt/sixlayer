//
//  PlatformSidebarRevealChromePolicyTests.swift
//  SixLayerFramework
//
//  Unit tests for split-edge sidebar reveal chrome policy (#324).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform Sidebar Reveal Chrome Policy")
struct PlatformSidebarRevealChromePolicyTests {

    @Test func isExplicitDetailOnly_distinguishesAutomaticFromDetailOnly() {
        #expect(!NavigationSplitViewVisibility.automatic.isExplicitDetailOnly)
        #expect(NavigationSplitViewVisibility.detailOnly.isExplicitDetailOnly)
    }

    @Test func showsAffordance_onlyWhenDetailOnly() {
        #expect(PlatformSidebarRevealChromePolicy.showsAffordance(for: .detailOnly))
        #expect(!PlatformSidebarRevealChromePolicy.showsAffordance(for: .all))
        #expect(!PlatformSidebarRevealChromePolicy.showsAffordance(for: .automatic))
        #if os(iOS)
        if #available(iOS 17.0, *) {
            #expect(!PlatformSidebarRevealChromePolicy.showsAffordance(for: .doubleColumn))
        }
        #endif
    }

    @Test func visibilityAfterReveal_expandsFromDetailOnly() {
        #expect(PlatformSidebarRevealChromePolicy.visibilityAfterReveal() == .all)
    }

    @Test func shouldApplyRevealGesture_whenDetailOnly_matchesPlatformCapability() {
        #expect(!PlatformSidebarRevealChromePolicy.shouldApplyRevealGesture(for: .all))
        #expect(!PlatformSidebarRevealChromePolicy.shouldApplyRevealGesture(for: .automatic))

        let detailOnlyGesture = PlatformSidebarRevealChromePolicy.shouldApplyRevealGesture(for: .detailOnly)
        switch SixLayerPlatform.current {
        case .iOS:
            #expect(detailOnlyGesture, "iOS should coordinate leading-edge reveal when detail-only")
        case .macOS, .tvOS, .watchOS, .visionOS:
            #expect(!detailOnlyGesture, "Non-iOS hosts use visual-only chrome for split-edge reveal")
        }
    }

    @Test func pullIndicatorVisibility_matchesDetailOnlyBinding() {
        #expect(PlatformSidebarRevealChromePolicy.pullIndicatorIsVisible(columnVisibility: .constant(.detailOnly)))
        #expect(!PlatformSidebarRevealChromePolicy.pullIndicatorIsVisible(columnVisibility: .constant(.all)))
    }
}
