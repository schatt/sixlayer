//
//  PlatformPresentationSize.swift
//  SixLayerFramework
//
//  Cross-platform presentation size hints (#384).
//  Public sheet/popover APIs take these; SwiftUI PresentationDetent is an iOS projection only.
//

import SwiftUI
import CoreGraphics

#if os(macOS)
import AppKit
#endif

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
        switch size {
        case .small:
            return smallSize
        case .medium:
            return mediumSize
        case .large:
            return largeSize
        case .exact(let width, let height):
            return CGSize(width: width, height: height)
        }
    }

    /// Largest unclamped size in the set (by area). Empty → `.large`.
    public static func unclampedMinSize(for sizes: [PlatformPresentationSize]) -> CGSize {
        guard !sizes.isEmpty else {
            return largeSize
        }
        return sizes
            .map(unclampedSize(for:))
            .max(by: { ($0.width * $0.height) < ($1.width * $1.height) })
            ?? largeSize
    }

    /// Upper-bound clamp: mins must fit within 90% of available window/screen.
    /// Does not raise sizes to absolute floors — presentation mins may be smaller than
    /// general `PlatformFrameHelpers.clampFrameSize` floors.
    public static func clampMinSize(_ size: CGSize, toMaxAvailable maxAvailable: CGSize) -> CGSize {
        let effectiveMax = CGSize(
            width: maxAvailable.width * 0.9,
            height: maxAvailable.height * 0.9
        )
        return CGSize(
            width: min(size.width, effectiveMax.width),
            height: min(size.height, effectiveMax.height)
        )
    }

    /// Resolve sizes then clamp to the given available space.
    public static func clampedMinSize(
        for sizes: [PlatformPresentationSize],
        maxAvailable: CGSize
    ) -> CGSize {
        clampMinSize(unclampedMinSize(for: sizes), toMaxAvailable: maxAvailable)
    }

    /// Live clamp using the current platform window/screen max via `PlatformFrameHelpers`.
    @MainActor
    public static func clampedMinSize(for sizes: [PlatformPresentationSize]) -> CGSize {
        let unclamped = unclampedMinSize(for: sizes)
        #if os(macOS)
        let screenSize: CGSize
        if let mainScreen = NSScreen.main {
            screenSize = mainScreen.visibleFrame.size
        } else {
            screenSize = CGSize(width: 1920, height: 1080)
        }
        return clampMinSize(unclamped, toMaxAvailable: screenSize)
        #elseif os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        return clampMinSize(unclamped, toMaxAvailable: PlatformFrameHelpers.getMaxFrameSize())
        #else
        return unclamped
        #endif
    }

    #if os(iOS)
    /// Map size hints to SwiftUI presentation detents (iOS sheet chrome only).
    @available(iOS 16.0, *)
    public static func presentationDetents(
        for sizes: [PlatformPresentationSize]
    ) -> Set<PresentationDetent> {
        let source = sizes.isEmpty ? [.large] : sizes
        var detents = Set<PresentationDetent>()
        for size in source {
            switch size {
            case .small:
                detents.insert(.medium)
            case .medium:
                detents.insert(.medium)
            case .large:
                detents.insert(.large)
            case .exact(_, let height):
                detents.insert(.height(height))
            }
        }
        return detents
    }
    #endif
}

// MARK: - View helpers

public extension View {
    /// Apply clamped min width/height from presentation size hints (#384).
    @MainActor
    func platformPresentationFrame(sizes: [PlatformPresentationSize]) -> some View {
        let minSize = PlatformPresentationSizeResolver.clampedMinSize(for: sizes)
        return self.frame(minWidth: minSize.width, minHeight: minSize.height)
    }
}
