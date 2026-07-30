//
//  PlatformPresentationSizeResolverTests.swift
//  SixLayerFrameworkTests
//
//  Locks PlatformPresentationSize preset table, multi-size largest selection,
//  and injectable upper-bound clamping (#384).
//

import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("PlatformPresentationSizeResolver")
struct PlatformPresentationSizeResolverTests {

    // MARK: - Unclamped presets

    @Test func unclampedSmallIs400x300() {
        let size = PlatformPresentationSizeResolver.unclampedSize(for: .small)
        #expect(size.width == 400)
        #expect(size.height == 300)
    }

    @Test func unclampedMediumIs820x640() {
        let size = PlatformPresentationSizeResolver.unclampedSize(for: .medium)
        #expect(size.width == 820)
        #expect(size.height == 640)
    }

    @Test func unclampedLargeIs1024x800() {
        let size = PlatformPresentationSizeResolver.unclampedSize(for: .large)
        #expect(size.width == 1024)
        #expect(size.height == 800)
    }

    @Test func unclampedExactUsesBothAxes() {
        let size = PlatformPresentationSizeResolver.unclampedSize(
            for: .exact(width: 900, height: 700)
        )
        #expect(size.width == 900)
        #expect(size.height == 700)
    }

    // MARK: - Multi-size → largest

    @Test func multiSizeUsesLargestByArea() {
        let size = PlatformPresentationSizeResolver.unclampedMinSize(
            for: [.small, .medium, .large]
        )
        #expect(size.width == 1024)
        #expect(size.height == 800)
    }

    @Test func multiSizeExactCanWinOverPreset() {
        let size = PlatformPresentationSizeResolver.unclampedMinSize(
            for: [.medium, .exact(width: 1200, height: 900)]
        )
        #expect(size.width == 1200)
        #expect(size.height == 900)
    }

    @Test func emptySizesFallBackToLarge() {
        let size = PlatformPresentationSizeResolver.unclampedMinSize(for: [])
        #expect(size.width == 1024)
        #expect(size.height == 800)
    }

    // MARK: - Clamp (injectable max — Split View / small screens)

    @Test func clampCapsToNinetyPercentOfAvailable() {
        let requested = CGSize(width: 1024, height: 800)
        let available = CGSize(width: 800, height: 600)
        let clamped = PlatformPresentationSizeResolver.clampMinSize(
            requested,
            toMaxAvailable: available
        )
        #expect(clamped.width == 720)  // 800 * 0.9
        #expect(clamped.height == 540) // 600 * 0.9
    }

    @Test func clampLeavesFittingSizeUnchanged() {
        let requested = CGSize(width: 400, height: 300)
        let available = CGSize(width: 1200, height: 900)
        let clamped = PlatformPresentationSizeResolver.clampMinSize(
            requested,
            toMaxAvailable: available
        )
        #expect(clamped.width == 400)
        #expect(clamped.height == 300)
    }

    @Test func clampedMinSizeForSizesAppliesTableThenClamp() {
        let clamped = PlatformPresentationSizeResolver.clampedMinSize(
            for: [.large],
            maxAvailable: CGSize(width: 800, height: 600)
        )
        #expect(clamped.width == 720)
        #expect(clamped.height == 540)
    }

    // MARK: - iOS detent projection (source contract)

    #if os(iOS)
    @Test @available(iOS 16.0, *)
    func presentationDetentsMapsPresets() {
        let detents = PlatformPresentationSizeResolver.presentationDetents(
            for: [.medium, .large]
        )
        #expect(detents.contains(.medium))
        #expect(detents.contains(.large))
    }

    @Test @available(iOS 16.0, *)
    func presentationDetentsMapsExactToHeight() {
        let detents = PlatformPresentationSizeResolver.presentationDetents(
            for: [.exact(width: 900, height: 700)]
        )
        #expect(detents.contains(.height(700)))
    }

    @Test @available(iOS 16.0, *)
    func presentationDetentsMapsSmallToMedium() {
        let detents = PlatformPresentationSizeResolver.presentationDetents(
            for: [.small]
        )
        #expect(detents.contains(.medium))
    }
    #endif
}
