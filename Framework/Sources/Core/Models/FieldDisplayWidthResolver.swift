//
//  FieldDisplayWidthResolver.swift
//  SixLayerFramework
//
//  Shared preferred-width resolution for FieldDisplayHints (GitHub #385).
//

import CoreGraphics
import Foundation

/// Platform-specific preferred point widths for `displayWidth` bands.
public struct FieldDisplayWidthPlatformBands: Sendable, Equatable {
    public var narrow: CGFloat
    public var medium: CGFloat
    public var wide: CGFloat

    public init(narrow: CGFloat, medium: CGFloat, wide: CGFloat) {
        self.narrow = narrow
        self.medium = medium
        self.wide = wide
    }

    /// Band table for a platform. Differences across platforms are intentional and documented.
    public static func forPlatform(_ platform: SixLayerPlatform) -> FieldDisplayWidthPlatformBands {
        // DELIBERATE RED stub (#385): identical on all platforms — wrong until green.
        _ = platform
        return FieldDisplayWidthPlatformBands(narrow: 150, medium: 200, wide: 400)
    }
}

/// Resolves a preferred field width claim from ``FieldDisplayHints``.
public enum FieldDisplayWidthResolver {
    /// Preferred horizontal field claim, optionally capped to `availableWidth`.
    ///
    /// Resolution order: numeric `displayWidth` → named band → `expectedLength` × metrics → nil.
    public static func preferredWidth(
        hints: FieldDisplayHints?,
        characterWidth: CGFloat,
        horizontalPadding: CGFloat = 0,
        bands: FieldDisplayWidthPlatformBands,
        availableWidth: CGFloat? = nil
    ) -> CGFloat? {
        // DELIBERATE RED stub (#385): ignore hints until green implementation.
        _ = (hints, characterWidth, horizontalPadding, bands, availableWidth)
        return nil
    }
}
