//
//  HIGMinimumTypographyPolicy.swift
//  SixLayerFramework
//
//  Platform minimum readable typography floors for automatic HIG compliance (#302).
//

import SwiftUI

/// Documented readable typography floors applied under automatic HIG compliance.
///
/// Semantic HIG styles (``.body``, ``.headline``, etc.) already scale with Dynamic Type.
/// Custom fixed sizes should use ``Font/higCompliantSystem(size:relativeTo:contentSize:platform:)``
/// so design-time values never fall below these floors.
public struct HIGMinimumTypographyPolicy: Sendable, Equatable {
    public let platform: SixLayerPlatform

    public init(platform: SixLayerPlatform) {
        self.platform = platform
    }

    /// Largest Dynamic Type step automatic compliance allows.
    public static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility5

    /// Minimum readable body-class point size at default Dynamic Type (``.large``).
    public var minimumReadableBodyPointSize: CGFloat {
        switch platform {
        case .iOS: return 17
        case .macOS: return 13
        case .tvOS: return 24
        case .watchOS: return 16
        case .visionOS: return 18
        }
    }

    /// Minimum readable caption-class point size at default Dynamic Type (``.large``).
    public var minimumReadableCaptionPointSize: CGFloat {
        switch platform {
        case .iOS: return 12
        case .macOS: return 11
        case .tvOS: return 17
        case .watchOS: return 12
        case .visionOS: return 13
        }
    }

    /// Readable floor for a semantic text style at default Dynamic Type.
    public func minimumReadablePointSize(for style: SixLayerTextStyle) -> CGFloat {
        switch style {
        case .caption1, .caption2, .footnote:
            return minimumReadableCaptionPointSize
        default:
            return minimumReadableBodyPointSize
        }
    }

    /// Escalates sub-minimum design sizes to the readable floor for ``style``.
    public func clampedDesignSize(
        _ designSize: CGFloat,
        relativeTo style: SixLayerTextStyle = .body
    ) -> CGFloat {
        max(designSize, minimumReadablePointSize(for: style))
    }

    public static func forCurrentPlatform() -> HIGMinimumTypographyPolicy {
        HIGMinimumTypographyPolicy(platform: RuntimeCapabilityDetection.currentPlatform)
    }
}

private struct HIGMinimumTypographyPolicyEnvironmentKey: EnvironmentKey {
    static let defaultValue: HIGMinimumTypographyPolicy? = nil
}

public extension EnvironmentValues {
    /// Active minimum typography policy when automatic HIG compliance is applied.
    var higMinimumTypographyPolicy: HIGMinimumTypographyPolicy? {
        get { self[HIGMinimumTypographyPolicyEnvironmentKey.self] }
        set { self[HIGMinimumTypographyPolicyEnvironmentKey.self] = newValue }
    }
}

public extension Font {
    /// System font scaled for Dynamic Type with HIG minimum readable floors enforced.
    static func higCompliantSystem(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: SixLayerTextStyle = .body,
        contentSize: SixLayerContentSizeCategory? = nil,
        platform: SixLayerPlatform? = nil
    ) -> Font {
        let resolvedPlatform = platform ?? RuntimeCapabilityDetection.currentPlatform
        let policy = HIGMinimumTypographyPolicy(platform: resolvedPlatform)
        let clampedSize = policy.clampedDesignSize(size, relativeTo: style)
        return DynamicFontResolver(minimumTypographyPolicy: policy).fontForScaledSystem(
            designSize: clampedSize,
            relativeTo: style,
            weight: weight,
            design: design,
            contentSize: contentSize
        )
    }
}
