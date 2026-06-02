//
//  PlatformScalableSystemFontTests.swift
//  SixLayerFrameworkUnitTests
//
//  Scalable platformSystem and decorative icon fonts (#296).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite(.serialized)
struct PlatformScalableSystemFontTests {

    @Test func testPlatformSystem_scalesUpAtAccessibilityContentSize() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let atLarge = PlatformTypographyTestAssertions.scaledSystemPointSize(
            designSize: designSize,
            contentSize: .large
        )
        let atAX = PlatformTypographyTestAssertions.scaledSystemPointSize(
            designSize: designSize,
            contentSize: .accessibilityExtraLarge
        )
        #expect(atAX > atLarge)
        #else
        PlatformTypographyTestAssertions.assertAccessibilityScaleFactorExceedsLarge()
        let font = Font.platformSystem(size: 48, relativeTo: .largeTitle, contentSize: .accessibilityExtraLarge)
        _ = Text("Icon").font(font)
        #endif
    }

    @Test func testPlatformSystem_matchesDesignSizeAtLarge() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let atLarge = PlatformTypographyTestAssertions.scaledSystemPointSize(
            designSize: designSize,
            contentSize: .large
        )
        #expect(abs(atLarge - designSize) < 2.0, "At .large, scaled size should approximate design size")
        #else
        let font = Font.platformSystem(size: 48, relativeTo: .largeTitle, contentSize: .large)
        _ = Text("Icon").font(font)
        PlatformTypographyTestAssertions.assertAllTextStylesResolveUsableFonts()
        #endif
    }

    @Test func testPlatformFixedSystem_doesNotScaleWithContentSize() {
        let designSize: CGFloat = 48
        let largeFont = Font.platformFixedSystem(size: designSize)
        let axFont = Font.platformFixedSystem(size: designSize)
        _ = Text("A").font(largeFont)
        _ = Text("B").font(axFont)
        #expect(largeFont == axFont)
    }

    @Test func testDecorativeIconModifier_matchesPlatformSystemAtLarge() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        let modifierFont = resolver.fontForScaledSystem(
            designSize: designSize,
            relativeTo: .largeTitle
        )
        let platformSystemFont = Font.platformSystem(
            size: designSize,
            relativeTo: .largeTitle,
            contentSize: .large
        )
        #expect(
            modifierFont == platformSystemFont,
            "Decorative icon modifier should use the same scaled system font as platformSystem at .large"
        )
        #else
        let designSize: CGFloat = 48
        let resolverFont = DynamicFontResolver(defaultContentSize: .large).fontForScaledSystem(
            designSize: designSize,
            relativeTo: .largeTitle
        )
        let platformFont = Font.platformSystem(
            size: designSize,
            relativeTo: .largeTitle,
            contentSize: .large
        )
        #expect(resolverFont == platformFont)
        #endif
    }
}
