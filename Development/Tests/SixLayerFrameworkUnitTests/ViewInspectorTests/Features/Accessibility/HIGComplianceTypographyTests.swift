//
//  HIGComplianceTypographyTests.swift
//  SixLayerFrameworkTests
//
//  Validates automatic HIG compliance typography: Dynamic Type range support,
//  platform minimum readable sizes, and sub-minimum custom font clamping (#302).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Suite("HIG Compliance - Typography Scaling")
open class HIGComplianceTypographyTests: BaseTestClass {

    // MARK: - Helpers

    #if os(iOS) || os(macOS)
    @MainActor
    private func bodyPointSize(
        resolver: DynamicFontResolver,
        contentSize: SixLayerContentSizeCategory
    ) -> CGFloat {
        #if os(iOS)
        return resolver.uiFont(for: .body, contentSize: contentSize).pointSize
        #elseif os(macOS)
        return resolver.nsFont(for: .body, contentSize: contentSize).pointSize
        #endif
    }

    @MainActor
    private func captionPointSize(
        resolver: DynamicFontResolver,
        contentSize: SixLayerContentSizeCategory
    ) -> CGFloat {
        #if os(iOS)
        return resolver.uiFont(for: .caption1, contentSize: contentSize).pointSize
        #elseif os(macOS)
        return resolver.nsFont(for: .caption1, contentSize: contentSize).pointSize
        #endif
    }

    @MainActor
    private func scaledSystemPointSize(
        resolver: DynamicFontResolver,
        designSize: CGFloat,
        contentSize: SixLayerContentSizeCategory = .large
    ) -> CGFloat {
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
    #endif

    @MainActor
    private func complianceResolver(
        platform: SixLayerPlatform = RuntimeCapabilityDetection.currentPlatform
    ) -> DynamicFontResolver {
        HIGTypographyCompliance.complianceDynamicFontResolver(for: platform)
    }

    // MARK: - Dynamic Type Support

    @Test @MainActor func testTextSupportsDynamicType() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let resolver = complianceResolver()
        let atDefault = bodyPointSize(resolver: resolver, contentSize: .large)
        let atAccessibility = bodyPointSize(resolver: resolver, contentSize: .accessibility3)
        #expect(atAccessibility > atDefault, "Automatic compliance body text should scale with Dynamic Type")
        #else
        _ = Text("Test Text").automaticCompliance(named: "TextWithDynamicType")
        #expect(Bool(true))
        #endif
    }

    @Test @MainActor func testButtonTextSupportsDynamicType() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let resolver = complianceResolver()
        let atDefault = bodyPointSize(resolver: resolver, contentSize: .large)
        let atAccessibility = bodyPointSize(resolver: resolver, contentSize: .accessibility5)
        #expect(atAccessibility > atDefault, "Button label typography should scale through accessibility5")
        #else
        _ = Button("Test Button") { }.automaticCompliance(named: "ButtonWithDynamicType")
        #expect(Bool(true))
        #endif
    }

    @Test @MainActor func testLabelSupportsDynamicType() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let resolver = complianceResolver()
        let atDefault = bodyPointSize(resolver: resolver, contentSize: .medium)
        let atAccessibility = bodyPointSize(resolver: resolver, contentSize: .accessibility2)
        #expect(atAccessibility > atDefault, "Label typography should scale with accessibility sizes")
        #else
        _ = Label("Test Label", systemImage: "star").automaticCompliance(named: "LabelWithDynamicType")
        #expect(Bool(true))
        #endif
    }

    // MARK: - Accessibility Size Range

    @Test @MainActor func testTextSupportsAccessibilitySizes() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let resolver = complianceResolver()
        let atLarge = bodyPointSize(resolver: resolver, contentSize: .large)
        let atAX5 = bodyPointSize(resolver: resolver, contentSize: .accessibility5)
        #expect(atAX5 > atLarge, "Typography should remain readable through accessibility5")
        #else
        _ = Text("Accessibility Text").automaticCompliance(named: "TextWithAccessibilitySizes")
        #expect(Bool(true))
        #endif
    }

    // MARK: - Minimum Font Size

    @Test @MainActor func testBodyTextMeetsMinimumSizeRequirements() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let platform = RuntimeCapabilityDetection.currentPlatform
        let floor = HIGTypographyCompliance.minimumReadableBodyPointSize(for: platform)
        let resolver = complianceResolver(platform: platform)
        let bodySize = bodyPointSize(resolver: resolver, contentSize: .large)
        #expect(bodySize >= floor, "Semantic body typography should meet platform minimum readable size")
        #else
        _ = Text("Body Text").font(.body).automaticCompliance(named: "BodyTextWithMinimumSize")
        #expect(Bool(true))
        #endif
    }

    @Test @MainActor func testCaptionTextMeetsMinimumSizeRequirements() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let platform = RuntimeCapabilityDetection.currentPlatform
        let floor = HIGTypographyCompliance.minimumReadableCaptionPointSize(for: platform)
        let resolver = complianceResolver(platform: platform)
        let captionSize = captionPointSize(resolver: resolver, contentSize: .large)
        #expect(captionSize >= floor, "Semantic caption typography should meet platform minimum readable size")
        #else
        _ = Text("Caption Text").font(.caption).automaticCompliance(named: "CaptionTextWithMinimumSize")
        #expect(Bool(true))
        #endif
    }

    @Test @MainActor func testCustomFontSizeEnforcedMinimum() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let platform = RuntimeCapabilityDetection.currentPlatform
        let floor = HIGTypographyCompliance.minimumReadableBodyPointSize(for: platform)
        let resolver = complianceResolver(platform: platform)
        let clampedSize = scaledSystemPointSize(resolver: resolver, designSize: 10)
        #expect(clampedSize >= floor, "Sub-minimum custom design sizes should clamp to readable floor")
        #else
        _ = Text("Small Text")
            .font(.system(size: 10))
            .automaticCompliance(named: "CustomFontSizeWithMinimum")
        #expect(Bool(true))
        #endif
    }

    // MARK: - Platform-Specific Typography

    @Test @MainActor func testPlatformSpecificTypographySizes() async {
        initializeTestConfig()
        for platform in SixLayerPlatform.allCases {
            let bodyFloor = HIGTypographyCompliance.minimumReadableBodyPointSize(for: platform)
            let captionFloor = HIGTypographyCompliance.minimumReadableCaptionPointSize(for: platform)
            #expect(bodyFloor > 0)
            #expect(captionFloor > 0)
            #expect(captionFloor <= bodyFloor, "Caption floor should not exceed body floor on \(platform)")
        }
    }

    // MARK: - Cross-Platform

    @Test @MainActor func testDynamicTypeOnBothPlatforms() async {
        initializeTestConfig()
        #if os(iOS) || os(macOS)
        let platform = RuntimeCapabilityDetection.currentPlatform
        let resolver = complianceResolver(platform: platform)
        let atLarge = bodyPointSize(resolver: resolver, contentSize: .large)
        let atAccessibility = bodyPointSize(resolver: resolver, contentSize: .accessibility4)
        #expect(atAccessibility > atLarge, "Dynamic Type should scale on \(platform)")
        #else
        _ = Text("Cross-Platform Text").automaticCompliance(named: "CrossPlatformDynamicType")
        #expect(Bool(true))
        #endif
    }
}
