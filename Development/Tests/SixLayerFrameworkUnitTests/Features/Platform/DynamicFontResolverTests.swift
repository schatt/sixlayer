//
//  DynamicFontResolverTests.swift
//  SixLayerFrameworkUnitTests
//
//  Validates central Dynamic Type font resolution (#295).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Suite(.serialized)
struct DynamicFontResolverTests {

    @Test func testBodyFont_scalesBetweenLargeAndAccessibilityExtraLarge() {
        #if os(iOS) || os(macOS)
        PlatformTypographyTestAssertions.assertBodyPointSizeScalesUpToAccessibilityExtraLarge()
        #else
        PlatformTypographyTestAssertions.assertAltPlatformDynamicTypeContract()
        #endif
    }

    @Test func testExplicitContentSizeOverrideDiffersFromLarge() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        #if os(iOS)
        let atDefault = resolver.uiFont(for: .body, contentSize: nil).pointSize
        let atAX = resolver.uiFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        #elseif os(macOS)
        let atDefault = resolver.nsFont(for: .body, contentSize: nil).pointSize
        let atAX = resolver.nsFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        #endif
        #expect(atAX > atDefault, "Explicit accessibilityExtraLarge override should increase body size")
        #else
        PlatformTypographyTestAssertions.assertAccessibilityScaleFactorExceedsLarge()
        #endif
    }

    @Test func testAllTextStylesReturnUsableFonts() {
        PlatformTypographyTestAssertions.assertAllTextStylesResolveUsableFonts()
    }

    #if os(iOS)
    @Test func testUIFontBridgeMatchesFontResolution() {
        let resolver = DynamicFontResolver(defaultContentSize: .extraLarge)
        let uiFont = resolver.uiFont(for: .headline, contentSize: .extraLarge)
        #expect(uiFont.pointSize > 0)
        #expect(!uiFont.fontDescriptor.postscriptName.isEmpty)
    }
    #endif

    @Test func testHIGTypographySystemDelegatesToResolver() {
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        let large = HIGTypographySystem(for: .iOS, contentSize: .large)
        let accessibility = HIGTypographySystem(for: .iOS, contentSize: .accessibilityExtraLarge)
        #expect(large.body == resolver.font(for: .body, contentSize: .large))
        #expect(accessibility.body == resolver.font(for: .body, contentSize: .accessibilityExtraLarge))
        #expect(large.body != accessibility.body, "HIG body token should scale with content size")
        #else
        let system = HIGTypographySystem(for: SixLayerPlatform.current, contentSize: .large)
        _ = system.body
        PlatformTypographyTestAssertions.assertPolicyFloorsArePositive(
            for: PlatformTypographyTestAssertions.policyForCurrentPlatform()
        )
        #endif
    }
}
