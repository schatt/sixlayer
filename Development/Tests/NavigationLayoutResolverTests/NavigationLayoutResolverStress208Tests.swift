//
//  NavigationLayoutResolverStress208Tests.swift
//  Issue #202 slice 6 / #208 — stress matrix (Dynamic Type, long-form, RTL axis width, churn, persistence).
//

import Foundation
import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Navigation Layout Resolver — #208 stress matrix")
struct NavigationLayoutResolverStress208Tests {

    @Test
    func scaledMinimumDetailWidth_scalesBaseByDynamicType() {
        let base: CGFloat = 480
        let scaled = NavigationLayoutResolver.scaledMinimumDetailWidthForNestedSplit(base: base, dynamicTypeScale: 1.5)
        #expect(scaled == 720)
    }

    @Test
    func scaledMinimumDetailWidth_clampsExtremeScales() {
        let base: CGFloat = 100
        let low = NavigationLayoutResolver.scaledMinimumDetailWidthForNestedSplit(base: base, dynamicTypeScale: 0.1)
        let high = NavigationLayoutResolver.scaledMinimumDetailWidthForNestedSplit(base: base, dynamicTypeScale: 10)
        #expect(low == 50)
        #expect(high == 300)
    }

    @Test
    func additionalDetailWidth_capsLongFormBoost() {
        let boost = NavigationLayoutResolver.additionalDetailWidthForLongFormContent(estimatedExtraCharacters: 10_000)
        #expect(boost == 160)
    }

    @Test
    func additionalDetailWidth_scalesWithExtraCharacters() {
        let boost = NavigationLayoutResolver.additionalDetailWidthForLongFormContent(estimatedExtraCharacters: 1000)
        #expect(boost == 150)
    }

    @Test
    func effectiveDetailMinimumWidth_combinesDynamicTypeAndLongForm() {
        let metrics = NavigationLayoutStressMetrics(dynamicTypeScale: 1.5, estimatedLongFormExtraCharacters: 1000)
        let effective = NavigationLayoutResolver.effectiveDetailMinimumWidthForNestedSplit(stressMetrics: metrics)
        #expect(effective == 870)
    }

    @Test
    func resolveSettingsContainer_withStressMetrics_usesEffectiveMinimum() {
        let defaultRes = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: 1300)
        let stressed = NavigationLayoutResolver.resolveSettingsContainer(
            availableWidth: 1300,
            stressMetrics: NavigationLayoutStressMetrics(dynamicTypeScale: 1.5, estimatedLongFormExtraCharacters: 1000)
        )
        #expect(defaultRes.mode == .sideBySide)
        #expect(stressed.mode == .compactCollapsedOuter)
    }

    @Test
    func effectiveContentWidth_subtractsLeadingTrailingInsets() {
        let w = NavigationLayoutResolver.effectiveContentWidthForSplitAxis(
            containerWidth: 1000,
            leadingInset: 20,
            trailingInset: 30
        )
        #expect(w == 950)
    }

    /// RTL: when the caller passes **mirrored** leading/trailing insets, semantic content width along the axis is unchanged.
    @Test
    func effectiveContentWidth_mirroredLeadingTrailing_sameSemanticContentWidth() {
        let w: CGFloat = 800
        let a = NavigationLayoutResolver.effectiveContentWidthForSplitAxis(
            containerWidth: w,
            leadingInset: 16,
            trailingInset: 48
        )
        let b = NavigationLayoutResolver.effectiveContentWidthForSplitAxis(
            containerWidth: w,
            leadingInset: 48,
            trailingInset: 16
        )
        #expect(a == 736)
        #expect(b == 736)
        #expect(a == b)
    }

    @Test
    func compactPresentation_roundTripsCodable() throws {
        for p in [
            NavigationLayoutCompactPresentation.fullSplit,
            .detailOnlyCollapsedInner,
            .overlayOuterSidebar
        ] {
            let data = try JSONEncoder().encode(p)
            let decoded = try JSONDecoder().decode(NavigationLayoutCompactPresentation.self, from: data)
            #expect(decoded == p)
        }
    }

    @Test
    func stress208_randomResizeWalk_staysInValidPresentationModes() {
        var state = NavigationLayoutCompactPresentation.fullSplit
        var rng = Stress208LCG(seed: 0x208)
        for _ in 0 ..< 5000 {
            let width = CGFloat(rng.next() % 2500)
            state = NavigationLayoutResolver.layer4CompactPresentationForTransition(
                availableWidth: width,
                previousPresentation: state
            )
            switch state {
            case .fullSplit, .detailOnlyCollapsedInner, .overlayOuterSidebar:
                break
            }
        }
    }

    @Test
    func resolveAppNavigationShell_matches_resolveSettingsContainer_withStressMetrics() {
        let stress = NavigationLayoutStressMetrics(dynamicTypeScale: 1.25, estimatedLongFormExtraCharacters: 500)
        let w: CGFloat = 1100
        let app = NavigationLayoutResolver.resolveAppNavigationShell(availableWidth: w, stressMetrics: stress)
        let settings = NavigationLayoutResolver.resolveSettingsContainer(availableWidth: w, stressMetrics: stress)
        #expect(app == settings)
    }
}

// MARK: - Deterministic churn

private struct Stress208LCG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1
        return state
    }
}
