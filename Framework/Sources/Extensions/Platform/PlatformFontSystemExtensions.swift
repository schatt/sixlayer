//
//  PlatformFontSystemExtensions.swift
//  SixLayerFramework
//
//  Cross-platform font extensions for unified typography operations
//  Provides platform-appropriate fonts across iOS and macOS
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Enhanced Platform Font System Extensions

/// Platform-specific font system that provides consistent typography
/// across iOS and macOS while respecting platform design guidelines
public extension Font {
    
    /// Platform-appropriate large title font
    /// iOS: .largeTitle; macOS: .system(size: 34, weight: .bold)
    static var platformLargeTitle: Font {
        #if os(iOS)
        return .largeTitle
        #elseif os(macOS)
        return .system(size: 34, weight: .bold, design: .default)
        #else
        return .largeTitle
        #endif
    }
    
    /// Platform-appropriate title font
    /// iOS: .title; macOS: .system(size: 28, weight: .bold)
    static var platformTitle: Font {
        #if os(iOS)
        return .title
        #elseif os(macOS)
        return .system(size: 28, weight: .bold, design: .default)
        #else
        return .title
        #endif
    }
    
    /// Platform-appropriate title2 font
    /// iOS: .title2; macOS: .system(size: 22, weight: .bold)
    static var platformTitle2: Font {
        #if os(iOS)
        return .title2
        #elseif os(macOS)
        return .system(size: 22, weight: .bold, design: .default)
        #else
        return .title2
        #endif
    }
    
    /// Platform-appropriate title3 font
    /// iOS: .title3; macOS: .system(size: 20, weight: .semibold)
    static var platformTitle3: Font {
        #if os(iOS)
        return .title3
        #elseif os(macOS)
        return .system(size: 20, weight: .semibold, design: .default)
        #else
        return .title3
        #endif
    }
    
    /// Platform-appropriate headline font
    /// iOS: .headline; macOS: .system(size: 17, weight: .semibold)
    static var platformHeadline: Font {
        #if os(iOS)
        return .headline
        #elseif os(macOS)
        return .system(size: 17, weight: .semibold, design: .default)
        #else
        return .headline
        #endif
    }
    
    /// Platform-appropriate body font
    /// iOS: .body; macOS: .system(size: 17, weight: .regular)
    static var platformBody: Font {
        #if os(iOS)
        return .body
        #elseif os(macOS)
        return .system(size: 17, weight: .regular, design: .default)
        #else
        return .body
        #endif
    }
    
    /// Platform-appropriate callout font
    /// iOS: .callout; macOS: .system(size: 16, weight: .regular)
    static var platformCallout: Font {
        #if os(iOS)
        return .callout
        #elseif os(macOS)
        return .system(size: 16, weight: .regular, design: .default)
        #else
        return .callout
        #endif
    }
    
    /// Platform-appropriate subheadline font
    /// iOS: .subheadline; macOS: .system(size: 15, weight: .regular)
    static var platformSubheadline: Font {
        #if os(iOS)
        return .subheadline
        #elseif os(macOS)
        return .system(size: 15, weight: .regular, design: .default)
        #else
        return .subheadline
        #endif
    }
    
    /// Platform-appropriate footnote font
    /// iOS: .footnote; macOS: .system(size: 13, weight: .regular)
    static var platformFootnote: Font {
        #if os(iOS)
        return .footnote
        #elseif os(macOS)
        return .system(size: 13, weight: .regular, design: .default)
        #else
        return .footnote
        #endif
    }
    
    /// Platform-appropriate caption font
    /// iOS: .caption; macOS: .system(size: 12, weight: .regular)
    static var platformCaption: Font {
        #if os(iOS)
        return .caption
        #elseif os(macOS)
        return .system(size: 12, weight: .regular, design: .default)
        #else
        return .caption
        #endif
    }
    
    /// Platform-appropriate caption2 font
    /// iOS: .caption2; macOS: .system(size: 11, weight: .regular)
    static var platformCaption2: Font {
        #if os(iOS)
        return .caption2
        #elseif os(macOS)
        return .system(size: 11, weight: .regular, design: .default)
        #else
        return .caption2
        #endif
    }
    
    // MARK: - Platform-Specific Font Access
    
    /// Platform-specific font accessor
    /// Returns UIFont on iOS, NSFont on macOS
    /// Note: SwiftUI Font doesn't directly expose platform fonts, so this provides
    /// a best-effort conversion. For precise control, use the static helper methods below.
    var platformFont: Any {
        #if os(iOS)
        // For platform fonts, return appropriate UIFont based on common text styles
        // This is a simplified mapping - for exact matches, use the static helpers
        return UIFont.preferredFont(forTextStyle: .body)
        #elseif os(macOS)
        // For platform fonts, return appropriate NSFont
        return NSFont.systemFont(ofSize: 17)
        #else
        return self
        #endif
    }
    
    // MARK: - UIKit/AppKit Interop Helpers
    
    #if os(iOS)
    /// Get UIFont for body text style (for UIKit interop)
    /// Use this when you need UIFont in UIViewRepresentable or other UIKit contexts
    static func uiFontBody() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    /// Get UIFont for headline text style (for UIKit interop)
    static func uiFontHeadline() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }
    
    /// Get UIFont for title text style (for UIKit interop)
    static func uiFontTitle() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .title1)
    }
    
    /// Get UIFont for caption text style (for UIKit interop)
    static func uiFontCaption() -> UIFont {
        return UIFont.preferredFont(forTextStyle: .caption1)
    }
    #elseif os(macOS)
    /// Get NSFont for body text style (for AppKit interop)
    /// Use this when you need NSFont in NSViewRepresentable or other AppKit contexts
    static func nsFontBody() -> NSFont {
        return NSFont.systemFont(ofSize: 17)
    }
    
    /// Get NSFont for headline text style (for AppKit interop)
    static func nsFontHeadline() -> NSFont {
        return NSFont.systemFont(ofSize: 17, weight: .semibold)
    }
    
    /// Get NSFont for title text style (for AppKit interop)
    static func nsFontTitle() -> NSFont {
        return NSFont.systemFont(ofSize: 28, weight: .bold)
    }
    
    /// Get NSFont for caption text style (for AppKit interop)
    static func nsFontCaption() -> NSFont {
        return NSFont.systemFont(ofSize: 12)
    }
    #endif
    
    // MARK: - Cross-Platform System Font Creation
    
    /// System font at a design-time point size, scaled for Dynamic Type.
    /// - Parameters:
    ///   - size: Design-time point size (e.g. empty-state icon at 48pt at `.large`).
    ///   - weight: Font weight (default: `.regular`).
    ///   - design: Font design (default: `.default`).
    ///   - relativeTo: Text style for scaling curve (default: `.body`; use `.largeTitle` for hero icons).
    ///   - contentSize: Override content size; `nil` uses resolver default / environment.
    static func platformSystem(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: SixLayerTextStyle = .body,
        contentSize: SixLayerContentSizeCategory? = nil
    ) -> Font {
        DynamicFontResolver().fontForScaledSystem(
            designSize: size,
            relativeTo: style,
            weight: weight,
            design: design,
            contentSize: contentSize
        )
    }

    /// Fixed system font that does not scale with Dynamic Type (overlays, camera chrome).
    static func platformFixedSystem(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

// MARK: - Decorative icon typography

private struct PlatformDecorativeIconFontModifier: ViewModifier {
    @Environment(\.dynamicFontResolver) private var resolver
    let designSize: CGFloat
    let relativeTo: SixLayerTextStyle

    func body(content: Content) -> some View {
        content.font(resolver.fontForScaledSystem(designSize: designSize, relativeTo: relativeTo))
    }
}

public extension View {
    /// Dynamic Type–scaled system font for decorative icons (empty states, hero glyphs).
    func platformDecorativeIconFont(
        designSize: CGFloat,
        relativeTo style: SixLayerTextStyle = .largeTitle
    ) -> some View {
        modifier(PlatformDecorativeIconFontModifier(designSize: designSize, relativeTo: style))
    }
}







