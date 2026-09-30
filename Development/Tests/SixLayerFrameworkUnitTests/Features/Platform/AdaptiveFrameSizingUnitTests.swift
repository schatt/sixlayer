//
//  AdaptiveFrameSizingUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Pure unit-lane coverage for AdaptiveFrameSizing (#468).
//

import Testing
@testable import SixLayerFramework

@Suite("AdaptiveFrameSizing (#468)")
struct AdaptiveFrameSizingUnitTests {

    @Test func simpleFormUsesBasePlusFieldAndSectionContributions() {
        let metrics = FormContentMetrics(
            fieldCount: 3,
            estimatedComplexity: .simple,
            preferredLayout: .compact,
            sectionCount: 2,
            hasComplexContent: false
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 575)
        #expect(size.minHeight == 600)
    }

    @Test func complexContentAddsHeightBonusAndCaps() {
        let metrics = FormContentMetrics(
            fieldCount: 12,
            estimatedComplexity: .complex,
            preferredLayout: .spacious,
            sectionCount: 6,
            hasComplexContent: true
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 800)
        #expect(size.minHeight == 1000)
    }

    @Test func veryWideFieldCountCapsWidthAt900() {
        let metrics = FormContentMetrics(
            fieldCount: 20,
            estimatedComplexity: .veryComplex,
            preferredLayout: .custom,
            sectionCount: 8,
            hasComplexContent: true
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 900)
        #expect(size.minHeight == 1000)
    }
}
