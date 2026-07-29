//
//  FieldDisplayWidthResolver.swift
//  SixLayerFramework
//
//  Shared preferred-width resolution for FieldDisplayHints (GitHub #385).
//

import CoreGraphics
import Foundation

/// Platform-specific preferred point widths for `displayWidth` bands.
///
/// Band *names* (`narrow` / `medium` / `wide`) are shared across platforms.
/// Point values differ by platform density (document changes here and in FieldHintsGuide).
public struct FieldDisplayWidthPlatformBands: Sendable, Equatable {
    public var narrow: CGFloat
    public var medium: CGFloat
    public var wide: CGFloat

    public init(narrow: CGFloat, medium: CGFloat, wide: CGFloat) {
        self.narrow = narrow
        self.medium = medium
        self.wide = wide
    }

    /// Band table for a platform.
    ///
    /// | Band   | iOS / touch | macOS / pointer |
    /// |--------|-------------|-----------------|
    /// | narrow | 120         | 150             |
    /// | medium | 180         | 200             |
    /// | wide   | 320         | 400             |
    ///
    /// Other platforms currently follow the iOS (compact) table.
    public static func forPlatform(_ platform: SixLayerPlatform) -> FieldDisplayWidthPlatformBands {
        switch platform {
        case .macOS:
            return FieldDisplayWidthPlatformBands(narrow: 150, medium: 200, wide: 400)
        case .iOS, .tvOS, .watchOS, .visionOS:
            return FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)
        }
    }
}

/// Resolves a preferred field width claim from ``FieldDisplayHints``.
public enum FieldDisplayWidthResolver {
    /// Preferred horizontal field claim, optionally capped to `availableWidth`.
    ///
    /// Resolution order:
    /// 1. numeric `displayWidth`
    /// 2. named band (`narrow` / `medium` / `wide`)
    /// 3. `expectedLength` × `characterWidth` + `horizontalPadding`
    /// 4. `nil` (flexible within the window; caller still caps to container)
    public static func preferredWidth(
        hints: FieldDisplayHints?,
        characterWidth: CGFloat,
        horizontalPadding: CGFloat = 0,
        bands: FieldDisplayWidthPlatformBands,
        availableWidth: CGFloat? = nil
    ) -> CGFloat? {
        guard let hints else { return nil }

        let uncapped: CGFloat?
        if let numeric = hints.displayWidthValue() {
            uncapped = numeric
        } else if hints.isNarrow {
            uncapped = bands.narrow
        } else if hints.isWide {
            uncapped = bands.wide
        } else if let displayWidth = hints.displayWidth,
                  displayWidth.lowercased() == "medium" {
            uncapped = bands.medium
        } else if let expectedLength = hints.expectedLength, expectedLength > 0 {
            uncapped = CGFloat(expectedLength) * characterWidth + horizontalPadding
        } else {
            uncapped = nil
        }

        guard let preferred = uncapped else { return nil }
        if let availableWidth {
            return min(preferred, availableWidth)
        }
        return preferred
    }
}
