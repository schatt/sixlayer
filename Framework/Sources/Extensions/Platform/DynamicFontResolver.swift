//
//  DynamicFontResolver.swift
//  SixLayerFramework
//
//  Central typography resolver: text style + content size → platform font (#295).
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Text style

/// Semantic text styles aligned with Apple text styles and design tokens.
public enum SixLayerTextStyle: String, CaseIterable, Sendable {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2
}

// MARK: - Resolver

/// Resolves SwiftUI and platform fonts for a text style at an explicit or default content size.
///
/// - iOS: Uses `UIFont.preferredFont(forTextStyle:compatibleWith:)` so sizes track Dynamic Type.
/// - macOS: Scales fixed platform baseline sizes by ``ContentSizeCategory/typographyScaleFactor``
///   (documented; macOS does not mirror iOS semantic fonts in ``Font/platform*``).
public struct DynamicFontResolver: Sendable {
    public let defaultContentSize: ContentSizeCategory

    public init(defaultContentSize: ContentSizeCategory = .large) {
        self.defaultContentSize = defaultContentSize
    }

    public func resolvedContentSize(_ override: ContentSizeCategory?) -> ContentSizeCategory {
        override ?? defaultContentSize
    }

    public func font(for style: SixLayerTextStyle, contentSize: ContentSizeCategory? = nil) -> Font {
        #if os(iOS)
        return Font(uiFont(for: style, contentSize: contentSize))
        #elseif os(macOS)
        return Font(nsFont(for: style, contentSize: contentSize))
        #else
        return semanticSwiftUIFont(for: style)
        #endif
    }

    #if os(iOS)
    public func uiFont(for style: SixLayerTextStyle, contentSize: ContentSizeCategory? = nil) -> UIFont {
        let category = resolvedContentSize(contentSize)
        let traits = UITraitCollection(preferredContentSizeCategory: category.uiContentSizeCategory)
        return UIFont.preferredFont(forTextStyle: style.uiTextStyle, compatibleWith: traits)
    }
    #endif

    #if os(macOS)
    public func nsFont(for style: SixLayerTextStyle, contentSize: ContentSizeCategory? = nil) -> NSFont {
        let category = resolvedContentSize(contentSize)
        let basePointSize = style.macOSBaselinePointSize
        let scaledSize = basePointSize * category.typographyScaleFactor
        let weight = style.macOSFontWeight
        return NSFont.systemFont(ofSize: scaledSize, weight: weight)
    }
    #endif

    private func semanticSwiftUIFont(for style: SixLayerTextStyle) -> Font {
        switch style {
        case .largeTitle: return .largeTitle
        case .title1: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption1: return .caption
        case .caption2: return .caption2
        }
    }
}

// MARK: - Content size mapping

public extension ContentSizeCategory {
    /// Relative scale vs `.large` (1.0). Used on macOS; iOS uses UIKit preferred fonts directly.
    var typographyScaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.82
        case .small: return 0.88
        case .medium: return 0.94
        case .large: return 1.0
        case .extraLarge: return 1.06
        case .extraExtraLarge: return 1.12
        case .extraExtraExtraLarge: return 1.18
        case .accessibilityMedium: return 1.31
        case .accessibilityLarge: return 1.44
        case .accessibilityExtraLarge: return 1.64
        case .accessibilityExtraExtraLarge: return 1.84
        case .accessibilityExtraExtraExtraLarge: return 2.04
        }
    }

    #if os(iOS)
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .extraSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .extraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        case .accessibilityMedium: return .accessibilityMedium
        case .accessibilityLarge: return .accessibilityLarge
        case .accessibilityExtraLarge: return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: return .accessibilityExtraExtraExtraLarge
        }
    }
    #endif
}

#if os(iOS)
private extension SixLayerTextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption1: return .caption1
        case .caption2: return .caption2
        }
    }
}
#endif

#if os(macOS)
private extension SixLayerTextStyle {
    var macOSBaselinePointSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption1: return 12
        case .caption2: return 11
        }
    }

    var macOSFontWeight: NSFont.Weight {
        switch self {
        case .largeTitle, .title1, .title2: return .bold
        case .title3, .headline: return .semibold
        case .body, .callout, .subheadline, .footnote, .caption1, .caption2: return .regular
        }
    }
}
#endif

// MARK: - Environment

private struct DynamicFontResolverEnvironmentKey: EnvironmentKey {
    static let defaultValue = DynamicFontResolver()
}

public extension EnvironmentValues {
    var dynamicFontResolver: DynamicFontResolver {
        get { self[DynamicFontResolverEnvironmentKey.self] }
        set { self[DynamicFontResolverEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Inject a ``DynamicFontResolver`` (e.g. for previews or tests with a fixed content size).
    func dynamicFontResolver(_ resolver: DynamicFontResolver) -> some View {
        environment(\.dynamicFontResolver, resolver)
    }
}
