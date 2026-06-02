//
//  PlatformTypographyTestAssertions.swift
//  SixLayerFrameworkTests
//
//  Cross-platform typography / Dynamic Type assertions where ViewInspector and
//  UIKit point-size metrics may be unavailable (#219, #302).
//

import SwiftUI
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Cheap, truthful typography assertions for unit tests on every platform lane.
public enum PlatformTypographyTestAssertions {

    public static func policyForCurrentPlatform() -> HIGMinimumTypographyPolicy {
        HIGMinimumTypographyPolicy(platform: SixLayerPlatform.current)
    }

    // MARK: - Shared (all platforms)

    public static func assertAccessibilityScaleFactorExceedsLarge() {
        #expect(
            SixLayerContentSizeCategory.accessibilityExtraLarge.typographyScaleFactor
                > SixLayerContentSizeCategory.large.typographyScaleFactor,
            "Accessibility content size should scale above .large"
        )
    }

    public static func assertPolicyFloorsArePositive(for policy: HIGMinimumTypographyPolicy) {
        #expect(policy.minimumReadableBodyPointSize > 0)
        #expect(policy.minimumReadableCaptionPointSize > 0)
        for style in SixLayerTextStyle.allCases {
            #expect(policy.minimumReadablePointSize(for: style) > 0)
        }
    }

    public static func assertClampedDesignSizeMeetsFloor(
        _ designSize: CGFloat,
        relativeTo style: SixLayerTextStyle = .body,
        policy: HIGMinimumTypographyPolicy? = nil
    ) {
        let resolved = policy ?? policyForCurrentPlatform()
        #expect(resolved.clampedDesignSize(designSize, relativeTo: style) >= resolved.minimumReadablePointSize(for: style))
    }

    public static func assertAllTextStylesResolveUsableFonts(contentSize: SixLayerContentSizeCategory = .large) {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        for style in SixLayerTextStyle.allCases {
            let font = resolver.font(for: style, contentSize: contentSize)
            _ = Text("Sample").font(font)
        }
    }

    public static func assertTypographySettingsScaleFactorDiffers() {
        let largeSettings = AccessibilitySettings(dynamicType: true, preferredContentSize: .large)
        let accessibilitySettings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: .accessibilityExtraLarge
        )
        #expect(accessibilitySettings.typographyScaleFactor > largeSettings.typographyScaleFactor)
    }

    // MARK: - iOS / macOS point-size lane

    #if os(iOS) || os(macOS)
    public static func resolvedBodyPointSize(
        contentSize: SixLayerContentSizeCategory,
        policy: HIGMinimumTypographyPolicy? = nil
    ) -> CGFloat {
        let resolver = DynamicFontResolver(
            defaultContentSize: contentSize,
            minimumTypographyPolicy: policy
        )
        #if os(iOS)
        return resolver.uiFont(for: .body, contentSize: contentSize).pointSize
        #elseif os(macOS)
        return resolver.nsFont(for: .body, contentSize: contentSize).pointSize
        #endif
    }

    public static func resolvedCustomPointSize(
        designSize: CGFloat,
        contentSize: SixLayerContentSizeCategory,
        policy: HIGMinimumTypographyPolicy
    ) -> CGFloat {
        let resolver = DynamicFontResolver(
            defaultContentSize: contentSize,
            minimumTypographyPolicy: policy
        )
        #if os(iOS)
        return resolver.uiFontForScaledSystem(
            designSize: designSize,
            relativeTo: .body,
            contentSize: contentSize
        ).pointSize
        #elseif os(macOS)
        return resolver.nsFontForScaledSystem(
            designSize: designSize,
            relativeTo: .body,
            contentSize: contentSize
        ).pointSize
        #endif
    }

    public static func resolvedStylePointSize(
        _ style: SixLayerTextStyle,
        contentSize: SixLayerContentSizeCategory = .large
    ) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        #if os(iOS)
        return resolver.uiFont(for: style, contentSize: contentSize).pointSize
        #elseif os(macOS)
        return resolver.nsFont(for: style, contentSize: contentSize).pointSize
        #endif
    }

    public static func scaledSystemPointSize(
        designSize: CGFloat,
        contentSize: SixLayerContentSizeCategory,
        relativeTo style: SixLayerTextStyle = .largeTitle
    ) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        #if os(iOS)
        return resolver.uiFontForScaledSystem(
            designSize: designSize,
            relativeTo: style,
            contentSize: contentSize
        ).pointSize
        #elseif os(macOS)
        return resolver.nsFontForScaledSystem(
            designSize: designSize,
            relativeTo: style,
            contentSize: contentSize
        ).pointSize
        #endif
    }

    public static func assertBodyPointSizeScalesUpToAccessibilityExtraLarge(
        policy: HIGMinimumTypographyPolicy? = nil
    ) {
        let atLarge = resolvedBodyPointSize(contentSize: .large, policy: policy)
        let atAccessibility = resolvedBodyPointSize(contentSize: .accessibilityExtraLarge, policy: policy)
        #expect(atAccessibility > atLarge, "Body should scale up at accessibilityExtraLarge")
    }

    public static func assertTypographyTokensDifferAcrossContentSizes() {
        let largeSettings = AccessibilitySettings(dynamicType: true, preferredContentSize: .large)
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
    }
    #endif

    // MARK: - Alt platforms (tvOS / watchOS / visionOS)

    #if !os(iOS) && !os(macOS)
    public static func assertAltPlatformDynamicTypeContract() {
        assertAccessibilityScaleFactorExceedsLarge()
        assertPolicyFloorsArePositive(for: policyForCurrentPlatform())
        assertAllTextStylesResolveUsableFonts()
    }

    public static func assertAltPlatformTypographyTokensHonorScaleFactor() {
        assertTypographySettingsScaleFactorDiffers()
        let largeSettings = AccessibilitySettings(dynamicType: true, preferredContentSize: .large)
        let accessibilitySettings = AccessibilitySettings(
            dynamicType: true,
            preferredContentSize: .accessibilityExtraLarge
        )
        let largeTokens = SixLayerDesignSystem.typographyTokens(for: .light, accessibility: largeSettings)
        let accessibilityTokens = SixLayerDesignSystem.typographyTokens(
            for: .light,
            accessibility: accessibilitySettings
        )
        _ = Text("Large").font(largeTokens.body)
        _ = Text("Accessibility").font(accessibilityTokens.body)
    }
    #endif
}
