//
//  PlatformPresentationSize.swift
//  SixLayerFramework
//
//  Cross-platform presentation size hints (#384).
//  Public sheet/popover APIs take these; SwiftUI PresentationDetent is an iOS projection only.
//

import SwiftUI
import CoreGraphics

/// Cross-platform intent for how large a presented surface should be.
///
/// - Important: Prefer this over raw SwiftUI `PresentationDetent`. Detents are an
///   iOS-only projection used for sheet snap heights; macOS and iPad multitasking
///   use clamped min width and height from the same size hint.
public enum PlatformPresentationSize: Sendable, Equatable {
    case small
    case medium
    case large
    case exact(width: CGFloat, height: CGFloat)
}

/// Resolves `PlatformPresentationSize` to unclamped sizes, clamped mins, and iOS detents.
public enum PlatformPresentationSizeResolver {

    public static let smallSize = CGSize(width: 400, height: 300)
    public static let mediumSize = CGSize(width: 820, height: 640)
    public static let largeSize = CGSize(width: 1024, height: 800)

    /// Canonical unclamped size for a single hint (before screen/window clamping).
    public static func unclampedSize(for size: PlatformPresentationSize) -> CGSize {
        // Deliberately wrong stub for TDD red (#384) — replace in green.
        switch size {
        case .small, .medium, .large, .exact:
            return CGSize(width: 1, height: 1)
        }
    }

    /// Largest unclamped size in the set (by area). Empty → `.large`.
    public static func unclampedMinSize(for sizes: [PlatformPresentationSize]) -> CGSize {
        // Deliberately wrong stub for TDD red (#384).
        CGSize(width: 1, height: 1)
    }

    /// Upper-bound clamp: mins must fit within 90% of available window/screen.
    public static func clampMinSize(_ size: CGSize, toMaxAvailable maxAvailable: CGSize) -> CGSize {
        // Deliberately wrong stub for TDD red (#384).
        size
    }

    /// Resolve sizes then clamp to the given available space.
    public static func clampedMinSize(
        for sizes: [PlatformPresentationSize],
        maxAvailable: CGSize
    ) -> CGSize {
        clampMinSize(unclampedMinSize(for: sizes), toMaxAvailable: maxAvailable)
    }

    #if os(iOS)
    /// Map size hints to SwiftUI presentation detents (iOS sheet chrome only).
    @available(iOS 16.0, *)
    public static func presentationDetents(
        for sizes: [PlatformPresentationSize]
    ) -> Set<PresentationDetent> {
        // Deliberately wrong stub for TDD red (#384).
        []
    }
    #endif
}
