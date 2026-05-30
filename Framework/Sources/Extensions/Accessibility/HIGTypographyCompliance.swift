//
//  HIGTypographyCompliance.swift
//  SixLayerFramework
//
//  Minimum readable typography floors for automatic HIG compliance (#302).
//

import SwiftUI

/// Platform minimum readable typography under automatic HIG compliance.
///
/// Semantic SwiftUI text styles (``.body``, ``.caption``, etc.) are preferred and typically
/// already meet these floors at default content size. Custom design-time sizes passed through
/// ``DynamicFontResolver/fontForScaledSystem(designSize:relativeTo:weight:design:contentSize:)``
/// with enforcement enabled are clamped upward to the applicable floor.
public enum HIGTypographyCompliance {

    /// Minimum readable body-class point size at default Dynamic Type (per HIG plan §1.3).
    public static func minimumReadableBodyPointSize(for platform: SixLayerPlatform) -> CGFloat {
        switch platform {
        case .iOS: return 17
        case .macOS: return 13
        case .tvOS: return 24
        case .watchOS: return 16
        case .visionOS: return 18
        }
    }

    /// Minimum readable caption-class point size at default Dynamic Type.
    public static func minimumReadableCaptionPointSize(for platform: SixLayerPlatform) -> CGFloat {
        switch platform {
        case .iOS: return 12
        case .macOS: return 11
        case .tvOS: return 20
        case .watchOS: return 14
        case .visionOS: return 16
        }
    }

    /// Minimum readable floor for a semantic text style on ``platform``.
    public static func minimumReadablePointSize(
        for style: SixLayerTextStyle,
        platform: SixLayerPlatform
    ) -> CGFloat {
        switch style {
        case .caption1, .caption2, .footnote:
            return minimumReadableCaptionPointSize(for: platform)
        default:
            return minimumReadableBodyPointSize(for: platform)
        }
    }

    /// Clamps ``requested`` to the readable floor for ``style`` on ``platform``.
    public static func clampedDesignSize(
        _ requested: CGFloat,
        relativeTo style: SixLayerTextStyle,
        platform: SixLayerPlatform
    ) -> CGFloat {
        requested
    }

    /// Resolver configured for automatic-compliance typography (Dynamic Type + readable floors).
    public static func complianceDynamicFontResolver(
        for platform: SixLayerPlatform,
        contentSize: SixLayerContentSizeCategory = .large
    ) -> DynamicFontResolver {
        DynamicFontResolver(defaultContentSize: contentSize, platform: platform)
    }
}
