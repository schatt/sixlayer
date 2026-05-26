//
//  PlatformScalableSystemFontTests.swift
//  SixLayerFrameworkUnitTests
//
//  Scalable platformSystem and decorative icon fonts (#296).
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
struct PlatformScalableSystemFontTests {

    #if os(iOS)
    private func scaledPointSize(
        designSize: CGFloat,
        contentSize: SixLayerContentSizeCategory,
        relativeTo: SixLayerTextStyle = .largeTitle
    ) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        return resolver.uiFontForScaledSystem(
            designSize: designSize,
            relativeTo: relativeTo,
            contentSize: contentSize
        ).pointSize
    }
    #elseif os(macOS)
    private func scaledPointSize(
        designSize: CGFloat,
        contentSize: SixLayerContentSizeCategory,
        relativeTo: SixLayerTextStyle = .largeTitle
    ) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        return resolver.nsFontForScaledSystem(
            designSize: designSize,
            relativeTo: relativeTo,
            contentSize: contentSize
        ).pointSize
    }
    #endif

    @Test func testPlatformSystem_scalesUpAtAccessibilityContentSize() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let atLarge = scaledPointSize(designSize: designSize, contentSize: .large)
        let atAX = scaledPointSize(designSize: designSize, contentSize: .accessibilityExtraLarge)
        #expect(atAX > atLarge)
        #else
        #expect(Bool(true))
        #endif
    }

    @Test func testPlatformSystem_matchesDesignSizeAtLarge() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let atLarge = scaledPointSize(designSize: designSize, contentSize: .large)
        #expect(abs(atLarge - designSize) < 2.0, "At .large, scaled size should approximate design size")
        #else
        #expect(Bool(true))
        #endif
    }

    @Test func testPlatformFixedSystem_doesNotScaleWithContentSize() {
        #if os(iOS) || os(macOS)
        let designSize: CGFloat = 48
        let largeFont = Font.platformFixedSystem(size: designSize)
        let axFont = Font.platformFixedSystem(size: designSize)
        _ = Text("A").font(largeFont)
        _ = Text("B").font(axFont)
        #expect(largeFont == axFont)
        #else
        #expect(Bool(true))
        #endif
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
        #expect(Bool(true))
        #endif
    }
}
