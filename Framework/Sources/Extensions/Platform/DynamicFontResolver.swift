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

// MARK: - Style → platform mapping

private extension SixLayerTextStyle {
    /// Reference font from ``Font/platform*`` (semantic on iOS, fixed baseline on macOS).
    var platformReferenceFont: Font {
        switch self {
        case .largeTitle: return .platformLargeTitle
        case .title1: return .platformTitle
        case .title2: return .platformTitle2
        case .title3: return .platformTitle3
        case .headline: return .platformHeadline
        case .body: return .platformBody
        case .callout: return .platformCallout
        case .subheadline: return .platformSubheadline
        case .footnote: return .platformFootnote
        case .caption1: return .platformCaption
        case .caption2: return .platformCaption2
        }
    }

    #if os(iOS)
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
    #endif

    #if os(macOS)
    /// Baseline point sizes — keep aligned with ``Font/platform*`` macOS definitions.
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
    #endif
}

// MARK: - Resolver

/// Resolves SwiftUI and platform fonts for a text style at an explicit or default content size.
///
/// - iOS: Uses `UIFont.preferredFont(forTextStyle:compatibleWith:)` so sizes track Dynamic Type.
/// - macOS: Scales ``Font/platform*`` baseline sizes by ``SixLayerContentSizeCategory/typographyScaleFactor``.
public struct DynamicFontResolver: Sendable {
    public let defaultContentSize: SixLayerContentSizeCategory
    public let enforceMinimumReadableSizes: Bool
    public let platform: SixLayerPlatform

    public init(
        defaultContentSize: SixLayerContentSizeCategory = .large,
        enforceMinimumReadableSizes: Bool = false,
        platform: SixLayerPlatform = .current
    ) {
        self.defaultContentSize = defaultContentSize
        self.enforceMinimumReadableSizes = enforceMinimumReadableSizes
        self.platform = platform
    }

    public func resolvedContentSize(_ override: SixLayerContentSizeCategory?) -> SixLayerContentSizeCategory {
        override ?? defaultContentSize
    }

    public func font(for style: SixLayerTextStyle, contentSize: SixLayerContentSizeCategory? = nil) -> Font {
        #if os(iOS)
        return Font(uiFont(for: style, contentSize: contentSize))
        #elseif os(macOS)
        return Font(nsFont(for: style, contentSize: contentSize))
        #else
        return style.platformReferenceFont
        #endif
    }

    #if os(iOS)
    public func uiFont(for style: SixLayerTextStyle, contentSize: SixLayerContentSizeCategory? = nil) -> UIFont {
        let category = resolvedContentSize(contentSize)
        let traits = UITraitCollection(preferredContentSizeCategory: category.uiContentSizeCategory)
        return UIFont.preferredFont(forTextStyle: style.uiTextStyle, compatibleWith: traits)
    }
    #endif

    #if os(macOS)
    public func nsFont(for style: SixLayerTextStyle, contentSize: SixLayerContentSizeCategory? = nil) -> NSFont {
        let category = resolvedContentSize(contentSize)
        let scaledSize = style.macOSBaselinePointSize * category.typographyScaleFactor
        return NSFont.systemFont(ofSize: scaledSize, weight: style.macOSFontWeight)
    }
    #endif

    /// System font at a design-time point size, scaled for Dynamic Type (``UIFontMetrics`` on iOS).
    public func fontForScaledSystem(
        designSize: CGFloat,
        relativeTo style: SixLayerTextStyle = .body,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        contentSize: SixLayerContentSizeCategory? = nil
    ) -> Font {
        #if os(iOS)
        return Font(uiFontForScaledSystem(
            designSize: designSize,
            relativeTo: style,
            weight: weight,
            contentSize: contentSize
        ))
        #elseif os(macOS)
        return Font(nsFontForScaledSystem(
            designSize: designSize,
            relativeTo: style,
            weight: weight,
            contentSize: contentSize
        ))
        #else
        return .system(size: designSize, weight: weight, design: design)
        #endif
    }

    #if os(iOS)
    public func uiFontForScaledSystem(
        designSize: CGFloat,
        relativeTo style: SixLayerTextStyle,
        weight: Font.Weight = .regular,
        contentSize: SixLayerContentSizeCategory? = nil
    ) -> UIFont {
        let category = resolvedContentSize(contentSize)
        let traits = UITraitCollection(preferredContentSizeCategory: category.uiContentSizeCategory)
        let metrics = UIFontMetrics(forTextStyle: style.uiTextStyle)
        let scaledSize = metrics.scaledValue(for: designSize, compatibleWith: traits)
        return UIFont.systemFont(ofSize: scaledSize, weight: weight.uiFontWeight)
    }
    #endif

    #if os(macOS)
    public func nsFontForScaledSystem(
        designSize: CGFloat,
        relativeTo style: SixLayerTextStyle,
        weight: Font.Weight = .regular,
        contentSize: SixLayerContentSizeCategory? = nil
    ) -> NSFont {
        let category = resolvedContentSize(contentSize)
        let scaledSize = designSize * category.typographyScaleFactor
        return NSFont.systemFont(ofSize: scaledSize, weight: weight.nsFontWeight)
    }
    #endif
}

#if os(iOS)
private extension Font.Weight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
#endif

#if os(macOS)
private extension Font.Weight {
    var nsFontWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
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
