//
//  VisualDesignSystemTypographyTokensTests.swift
//  SixLayerFrameworkUnitTests
//
//  Design-token typography scaling via DynamicFontResolver (#294).
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
struct VisualDesignSystemTypographyTokensTests {

    @Test func testTypographyScaleFactor_reflectsPreferredContentSize() {
        let settings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: .accessibilityExtraLarge
        )
        #expect(settings.typographyScaleFactor > 1.0)
        #expect(
            settings.typographyScaleFactor == SixLayerContentSizeCategory.accessibilityExtraLarge.typographyScaleFactor
        )
    }

    @Test func testTypographyScaleFactor_isNeutralWhenDynamicTypeDisabled() {
        let settings = AccessibilitySettings(
            dynamicType: false,
            preferredContentSize: .accessibilityExtraLarge
        )
        #expect(settings.typographyScaleFactor == 1.0)
    }

    @Test func testTypographyTokens_differAcrossContentSizes() {
        #if os(iOS) || os(macOS)
        let largeSettings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: .large
        )
        let accessibilitySettings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: .accessibilityExtraLarge
        )
        let largeTokens = SixLayerDesignSystem.typographyTokens(for: .light, accessibility: largeSettings)
        let accessibilityTokens = SixLayerDesignSystem.typographyTokens(
            for: .light,
            accessibility: accessibilitySettings
        )
        #expect(largeTokens.body != accessibilityTokens.body)
        #else
        #expect(Bool(true))
        #endif
    }

    #if os(iOS) || os(macOS)
    @Test func testTypographyTokens_matchDynamicFontResolver() {
        let contentSize = SixLayerContentSizeCategory.extraLarge
        let settings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: contentSize
        )
        let tokens = SixLayerDesignSystem.typographyTokens(for: .light, accessibility: settings)
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        #expect(tokens.body == resolver.font(for: .body, contentSize: contentSize))
        #expect(tokens.headline == resolver.font(for: .headline, contentSize: contentSize))
    }
    #endif
}
