//
//  VisualDesignSystemTypographyTokensTests.swift
//  SixLayerFrameworkUnitTests
//
//  Design-token typography scaling via DynamicFontResolver (#294).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

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
        PlatformTypographyTestAssertions.assertTypographyTokensDifferAcrossContentSizes()
        #else
        PlatformTypographyTestAssertions.assertAltPlatformTypographyTokensHonorScaleFactor()
        #endif
    }

    #if os(iOS) || os(macOS)
    @Test func testSixLayerDesignSystem_initHonorsAccessibilityProfile() {
        let large = SixLayerDesignSystem(
            accessibility: AccessibilitySettings(dynamicType: true, preferredContentSize: .large)
        )
        let accessibility = SixLayerDesignSystem(
            accessibility: AccessibilitySettings(
                dynamicType: true,
                preferredContentSize: .accessibilityExtraLarge
            )
        )
        #expect(large.typography(for: .light).body != accessibility.typography(for: .light).body)
    }

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
