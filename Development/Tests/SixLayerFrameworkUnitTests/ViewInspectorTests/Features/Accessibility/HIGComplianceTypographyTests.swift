import Testing

//
//  HIGComplianceTypographyTests.swift
//  SixLayerFrameworkTests
//
//  Validates automatic HIG compliance typography: Dynamic Type range, platform
//  minimum readable floors, and sub-minimum custom size clamping (#302).
//

import SwiftUI
@testable import SixLayerFramework
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

@Suite("HIG Compliance - Typography Scaling", .serialized)
open class HIGComplianceTypographyTests: BaseTestClass {

    // MARK: - Helpers

    @MainActor
    private func hostTypographyView<V: View>(
        _ view: V,
        dynamicTypeSize dynamicType: DynamicTypeSize? = nil
    ) -> Any? {
        initializeTestConfig()
        return runWithTaskLocalConfig {
            let hosted: AnyView = {
                let compliant = view.automaticCompliance(named: "HIGTypographyHost")
                if let dynamicType {
                    return AnyView(compliant.dynamicTypeSize(dynamicType))
                }
                return AnyView(compliant)
            }()
            return Self.hostRootPlatformView(
                hosted,
                forceLayout: true,
                exposeContentAccessibility: true
            )
        }
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    private func verifyTypographyViewHosts<V: View>(
        _ view: V,
        dynamicTypeSize dynamicType: DynamicTypeSize? = nil,
        description: String
    ) {
        let root = hostTypographyView(view, dynamicTypeSize: dynamicType)
        #expect(root != nil, "\(description) should host with automatic compliance")
    }
    #endif

    private func currentPolicy() -> HIGMinimumTypographyPolicy {
        PlatformTypographyTestAssertions.policyForCurrentPlatform()
    }

    @MainActor
    private func assertHostedTypographyScalesOrAltContract(description: String) async {
        #if os(iOS) || os(macOS)
        PlatformTypographyTestAssertions.assertBodyPointSizeScalesUpToAccessibilityExtraLarge()
        #elseif canImport(UIKit) && !os(watchOS)
        _ = description
        PlatformTypographyTestAssertions.assertAccessibilityScaleFactorExceedsLarge()
        #else
        _ = description
        PlatformTypographyTestAssertions.assertAltPlatformDynamicTypeContract()
        #endif
    }

    // MARK: - Dynamic Type Support Tests

    @Test @MainActor func testTextSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let view = Text("Test Text")
            .font(.body)
        verifyTypographyViewHosts(view, description: "Body text at default Dynamic Type")
        verifyTypographyViewHosts(
            view,
            dynamicTypeSize: .accessibility3,
            description: "Body text at accessibility3"
        )
        #endif
        await assertHostedTypographyScalesOrAltContract(description: "Body text under automatic compliance")
    }

    @Test @MainActor func testButtonTextSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let button = Button("Test Button") { }
        verifyTypographyViewHosts(button, description: "Button at default Dynamic Type")
        verifyTypographyViewHosts(
            button,
            dynamicTypeSize: .accessibility3,
            description: "Button at accessibility3"
        )
        #endif
        await assertHostedTypographyScalesOrAltContract(description: "Button text")
    }

    @Test @MainActor func testLabelSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let label = Label("Test Label", systemImage: "star")
        verifyTypographyViewHosts(label, description: "Label at default Dynamic Type")
        verifyTypographyViewHosts(
            label,
            dynamicTypeSize: .accessibility3,
            description: "Label at accessibility3"
        )
        #endif
        await assertHostedTypographyScalesOrAltContract(description: "Label text")
    }

    // MARK: - Accessibility Size Range Tests

    @Test func testTextSupportsAccessibilitySizes() {
        #expect(
            HIGMinimumTypographyPolicy.maximumDynamicTypeSize == .accessibility5,
            "Automatic compliance should allow scaling through accessibility5"
        )
        #if os(iOS) || os(macOS)
        let policy = currentPolicy()
        PlatformTypographyTestAssertions.assertBodyPointSizeScalesUpToAccessibilityExtraLarge(policy: policy)
        #expect(
            PlatformTypographyTestAssertions.resolvedBodyPointSize(contentSize: .large, policy: policy)
                >= policy.minimumReadableBodyPointSize
        )
        #else
        PlatformTypographyTestAssertions.assertAltPlatformDynamicTypeContract()
        #endif
    }

    // MARK: - Minimum Font Size Tests

    @Test func testBodyTextMeetsMinimumSizeRequirements() {
        let policy = currentPolicy()
        #if os(iOS) || os(macOS)
        let bodySize = PlatformTypographyTestAssertions.resolvedBodyPointSize(contentSize: .large, policy: policy)
        #expect(
            bodySize >= policy.minimumReadableBodyPointSize,
            "Body at .large should meet \(policy.platform) minimum \(policy.minimumReadableBodyPointSize)pt"
        )
        #else
        PlatformTypographyTestAssertions.assertPolicyFloorsArePositive(for: policy)
        #endif
    }

    @Test func testCaptionTextMeetsMinimumSizeRequirements() {
        let policy = currentPolicy()
        #if os(iOS) || os(macOS)
        let captionSize = PlatformTypographyTestAssertions.resolvedStylePointSize(.caption1, contentSize: .large)
        #expect(
            captionSize >= policy.minimumReadableCaptionPointSize,
            "Caption at .large should meet \(policy.platform) minimum \(policy.minimumReadableCaptionPointSize)pt"
        )
        #else
        #expect(policy.minimumReadableCaptionPointSize > 0)
        #endif
    }

    @Test func testCustomFontSizeEnforcedMinimum() {
        let policy = currentPolicy()
        PlatformTypographyTestAssertions.assertClampedDesignSizeMeetsFloor(10, relativeTo: .body, policy: policy)
        #if os(iOS) || os(macOS)
        let clampedSize = PlatformTypographyTestAssertions.resolvedCustomPointSize(
            designSize: 10,
            contentSize: .large,
            policy: policy
        )
        #expect(
            clampedSize >= policy.minimumReadableBodyPointSize,
            "Resolver with policy should clamp 10pt custom body font to readable floor"
        )
        let compliantFont = Font.higCompliantSystem(size: 10, platform: policy.platform)
        _ = Text("Small Text").font(compliantFont)
        #expect(
            policy.clampedDesignSize(10, relativeTo: .body) == policy.minimumReadableBodyPointSize,
            "10pt on \(policy.platform) should clamp to body floor"
        )
        #else
        #expect(policy.clampedDesignSize(10, relativeTo: .body) == policy.minimumReadableBodyPointSize)
        #endif
    }

    // MARK: - Platform-Specific Typography Size Tests

    @Test func testPlatformSpecificTypographySizes() {
        let policy = currentPolicy()
        let styles: [SixLayerTextStyle] = [
            .largeTitle, .title1, .headline, .body, .caption1
        ]
        #if os(iOS) || os(macOS)
        for style in styles {
            let pointSize = PlatformTypographyTestAssertions.resolvedStylePointSize(style, contentSize: .large)
            #expect(
                pointSize >= policy.minimumReadablePointSize(for: style),
                "\(style) should meet readable floor on \(policy.platform)"
            )
        }
        #else
        PlatformTypographyTestAssertions.assertPolicyFloorsArePositive(for: policy)
        PlatformTypographyTestAssertions.assertAllTextStylesResolveUsableFonts()
        _ = styles
        #endif
    }

    // MARK: - Cross-Platform Tests

    @Test func testDynamicTypeOnBothPlatforms() {
        #if os(iOS) || os(macOS)
        PlatformTypographyTestAssertions.assertBodyPointSizeScalesUpToAccessibilityExtraLarge()
        #else
        PlatformTypographyTestAssertions.assertAltPlatformDynamicTypeContract()
        #endif
    }
}
