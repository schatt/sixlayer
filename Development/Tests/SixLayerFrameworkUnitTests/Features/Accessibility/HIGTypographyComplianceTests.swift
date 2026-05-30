//
//  HIGTypographyComplianceTests.swift
//  SixLayerFrameworkUnitTests
//
//  Minimum readable typography floors for automatic HIG compliance (#302).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Suite struct HIGTypographyComplianceTests {

    @Test func testMinimumReadableBodyPointSize_matchesHIGPlan() {
        #expect(HIGTypographyCompliance.minimumReadableBodyPointSize(for: .iOS) == 17)
        #expect(HIGTypographyCompliance.minimumReadableBodyPointSize(for: .macOS) == 13)
        #expect(HIGTypographyCompliance.minimumReadableBodyPointSize(for: .tvOS) == 24)
        #expect(HIGTypographyCompliance.minimumReadableBodyPointSize(for: .watchOS) == 16)
        #expect(HIGTypographyCompliance.minimumReadableBodyPointSize(for: .visionOS) == 18)
    }

    @Test func testClampedDesignSize_raisesSubMinimumBodySize() {
        let floor = HIGTypographyCompliance.minimumReadableBodyPointSize(for: .iOS)
        let clamped = HIGTypographyCompliance.clampedDesignSize(
            10,
            relativeTo: .body,
            platform: .iOS
        )
        #expect(clamped >= floor, "10pt body design size on iOS should clamp to at least \(floor)pt")
    }

    @Test func testClampedDesignSize_preservesAboveMinimum() {
        let clamped = HIGTypographyCompliance.clampedDesignSize(
            24,
            relativeTo: .body,
            platform: .iOS
        )
        #expect(clamped == 24, "Sizes already above the floor should pass through unchanged")
    }

    @Test func testComplianceResolver_clampsScaledSystemFont() {
        #if os(iOS) || os(macOS)
        let platform: SixLayerPlatform = .iOS
        let resolver = HIGTypographyCompliance.complianceDynamicFontResolver(for: platform)
        let floor = HIGTypographyCompliance.minimumReadableBodyPointSize(for: platform)
        #if os(iOS)
        let pointSize = resolver.uiFontForScaledSystem(
            designSize: 10,
            relativeTo: .body,
            contentSize: .large
        ).pointSize
        #elseif os(macOS)
        let pointSize = resolver.nsFontForScaledSystem(
            designSize: 10,
            relativeTo: .body,
            contentSize: .large
        ).pointSize
        #endif
        #expect(pointSize >= floor, "Compliance resolver should enforce readable body floor")
        #else
        #expect(Bool(true))
        #endif
    }

    @Test func testComplianceResolver_scalesBodyBetweenLargeAndAccessibility() {
        #if os(iOS) || os(macOS)
        let platform: SixLayerPlatform = .iOS
        let resolver = HIGTypographyCompliance.complianceDynamicFontResolver(for: platform)
        #if os(iOS)
        let atLarge = resolver.uiFont(for: .body, contentSize: .large).pointSize
        let atAccessibility = resolver.uiFont(for: .body, contentSize: .accessibility3).pointSize
        #elseif os(macOS)
        let atLarge = resolver.nsFont(for: .body, contentSize: .large).pointSize
        let atAccessibility = resolver.nsFont(for: .body, contentSize: .accessibility3).pointSize
        #endif
        #expect(atAccessibility > atLarge, "Compliance body typography should scale with Dynamic Type")
        #else
        #expect(Bool(true))
        #endif
    }
}
