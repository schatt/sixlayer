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
    private func hostTypographyView<V: View>(_ view: V) -> Any? {
        initializeTestConfig()
        return runWithTaskLocalConfig {
            Self.hostRootPlatformView(
                view.automaticCompliance(named: "HIGTypographyHost"),
                forceLayout: true,
                exposeContentAccessibility: true
            )
        }
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    private func maximumUILabelPointSize(in root: Any?) -> CGFloat? {
        guard let rootView = root as? UIView else { return nil }
        var maxSize: CGFloat = 0
        var found = false

        func visit(_ view: UIView) {
            if let label = view as? UILabel {
                maxSize = max(maxSize, label.font.pointSize)
                found = true
            }
            for subview in view.subviews {
                visit(subview)
            }
        }

        visit(rootView)
        return found ? maxSize : nil
    }
    #endif

    #if os(iOS) || os(macOS)
    private func resolvedBodyPointSize(
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

    private func resolvedCustomPointSize(
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
    #endif

    private func currentPolicy() -> HIGMinimumTypographyPolicy {
        HIGMinimumTypographyPolicy(platform: SixLayerPlatform.current)
    }

    // MARK: - Dynamic Type Support Tests

    @Test @MainActor func testTextSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let view = Text("Test Text")
            .font(.body)
        let defaultRoot = hostTypographyView(view)
        let scaledRoot = hostTypographyView(view.dynamicTypeSize(.accessibility3))
        let defaultSize = maximumUILabelPointSize(in: defaultRoot)
        let scaledSize = maximumUILabelPointSize(in: scaledRoot)
        #expect(defaultRoot != nil && scaledRoot != nil, "Text host should layout")
        #expect(defaultSize != nil && scaledSize != nil, "Hosted Text should expose UILabel font metrics")
        #expect(
            scaledSize! > defaultSize!,
            "Body text under automatic compliance should scale up at accessibility3"
        )
        #else
        let resolver = DynamicFontResolver()
        _ = resolver.font(for: .body, contentSize: .accessibilityExtraLarge)
        #expect(Bool(true), "Non-UIKit lane uses resolver Dynamic Type contract")
        #endif
    }

    @Test @MainActor func testButtonTextSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let button = Button("Test Button") { }
        let defaultRoot = hostTypographyView(button)
        let scaledRoot = hostTypographyView(button.dynamicTypeSize(.accessibility3))
        let defaultSize = maximumUILabelPointSize(in: defaultRoot)
        let scaledSize = maximumUILabelPointSize(in: scaledRoot)
        #expect(defaultRoot != nil && scaledRoot != nil)
        #expect(defaultSize != nil && scaledSize != nil, "Button label should expose font metrics")
        #expect(scaledSize! > defaultSize!, "Button text should scale with Dynamic Type")
        #else
        #expect(Bool(true))
        #endif
    }

    @Test @MainActor func testLabelSupportsDynamicType() async {
        #if canImport(UIKit) && !os(watchOS)
        let label = Label("Test Label", systemImage: "star")
        let defaultRoot = hostTypographyView(label)
        let scaledRoot = hostTypographyView(label.dynamicTypeSize(.accessibility3))
        let defaultSize = maximumUILabelPointSize(in: defaultRoot)
        let scaledSize = maximumUILabelPointSize(in: scaledRoot)
        #expect(defaultRoot != nil && scaledRoot != nil)
        #expect(defaultSize != nil && scaledSize != nil, "Label title should expose font metrics")
        #expect(scaledSize! > defaultSize!, "Label text should scale with Dynamic Type")
        #else
        #expect(Bool(true))
        #endif
    }

    // MARK: - Accessibility Size Range Tests

    @Test func testTextSupportsAccessibilitySizes() {
        #expect(
            HIGMinimumTypographyPolicy.maximumDynamicTypeSize == .accessibility5,
            "Automatic compliance should allow scaling through accessibility5"
        )
        #if os(iOS) || os(macOS)
        let policy = currentPolicy()
        let atLarge = resolvedBodyPointSize(contentSize: .large)
        let atAccessibility = resolvedBodyPointSize(contentSize: .accessibilityExtraLarge)
        #expect(
            atAccessibility > atLarge,
            "Body should remain readable and larger at accessibilityExtraLarge"
        )
        #expect(atLarge >= policy.minimumReadableBodyPointSize)
        #else
        #expect(Bool(true))
        #endif
    }

    // MARK: - Minimum Font Size Tests

    @Test func testBodyTextMeetsMinimumSizeRequirements() {
        let policy = currentPolicy()
        #if os(iOS) || os(macOS)
        let bodySize = resolvedBodyPointSize(contentSize: .large)
        #expect(
            bodySize >= policy.minimumReadableBodyPointSize,
            "Body at .large should meet \(policy.platform) minimum \(policy.minimumReadableBodyPointSize)pt"
        )
        #else
        #expect(policy.minimumReadableBodyPointSize > 0)
        #endif
    }

    @Test func testCaptionTextMeetsMinimumSizeRequirements() {
        let policy = currentPolicy()
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        #if os(iOS)
        let captionSize = resolver.uiFont(for: .caption1, contentSize: .large).pointSize
        #elseif os(macOS)
        let captionSize = resolver.nsFont(for: .caption1, contentSize: .large).pointSize
        #endif
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
        #expect(
            policy.clampedDesignSize(10, relativeTo: .body) >= policy.minimumReadableBodyPointSize,
            "Policy should escalate 10pt body-relative design size to readable floor"
        )
        #if os(iOS) || os(macOS)
        let clampedSize = resolvedCustomPointSize(
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
        #expect(Bool(true))
        #endif
    }

    // MARK: - Platform-Specific Typography Size Tests

    @Test func testPlatformSpecificTypographySizes() {
        let policy = currentPolicy()
        let styles: [SixLayerTextStyle] = [
            .largeTitle, .title1, .headline, .body, .caption1
        ]
        #if os(iOS) || os(macOS)
        let resolver = DynamicFontResolver(defaultContentSize: .large)
        for style in styles {
            #if os(iOS)
            let pointSize = resolver.uiFont(for: style, contentSize: .large).pointSize
            #elseif os(macOS)
            let pointSize = resolver.nsFont(for: style, contentSize: .large).pointSize
            #endif
            #expect(
                pointSize >= policy.minimumReadablePointSize(for: style),
                "\(style) should meet readable floor on \(policy.platform)"
            )
        }
        #else
        for style in styles {
            #expect(policy.minimumReadablePointSize(for: style) > 0)
        }
        #endif
    }

    // MARK: - Cross-Platform Tests

    @Test func testDynamicTypeOnBothPlatforms() {
        #if os(iOS) || os(macOS)
        let atLarge = resolvedBodyPointSize(contentSize: .large)
        let atAccessibility = resolvedBodyPointSize(contentSize: .accessibilityExtraLarge)
        #expect(atAccessibility > atLarge, "Dynamic Type should increase body size on hosted platform")
        #else
        let policy = currentPolicy()
        #expect(policy.minimumReadableBodyPointSize > 0)
        #endif
    }
}
