//
//  TextModifierViewExtensions.swift
//  SixLayerFramework
//
//  View extensions that replicate Text-specific modifiers
//  Implements Issue #174: View Extensions for Text Modifiers
//
//  BUSINESS PURPOSE: Enable chaining Text modifiers after .basicAutomaticCompliance()
//  which returns some View, breaking Text's type-preserving modifier chain
//

import SwiftUI

// MARK: - View Extensions for Text Modifiers

/// View extensions that replicate Text-specific modifiers
/// These enable chaining Text modifiers after modifiers that return `some View`
/// (like `.basicAutomaticCompliance()`)
public extension View {
    
    /// Apply bold font weight to any View
    /// 
    /// This extension replicates Text's `.bold()` modifier for all Views.
    /// Uses `.fontWeight()` which preserves the existing font and only changes weight.
    /// On Text views, it applies bold font weight.
    /// On container views (VStack, etc.), it propagates to children via environment.
    /// On non-text views (Image, Shape), it has no visible effect but doesn't error.
    ///
    /// - Returns: A view with bold font weight applied (or unchanged if not applicable)
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Hello")
    ///     .font(.title)
    ///     .basicAutomaticCompliance()
    ///     .bold()  // ✅ Preserves .title font, applies bold weight
    /// ```
    func bold() -> some View {
        // Use .fontWeight() which preserves the existing font
        // This works for Text views and propagates via environment to children
        // For non-text views, this has no visible effect (expected behavior)
        self.fontWeight(.bold)
    }
    
    /// Apply italic style to any View
    /// 
    /// This extension replicates Text's `.italic()` modifier for all Views.
    /// Preserves the existing font from the environment and applies italic to it.
    /// On Text views, it applies italic style.
    /// On container views (VStack, etc.), it propagates to children via environment.
    /// On non-text views (Image, Shape), it has no visible effect but doesn't error.
    ///
    /// - Returns: A view with italic style applied (or unchanged if not applicable)
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Hello")
    ///     .font(.title)
    ///     .basicAutomaticCompliance()
    ///     .italic()  // ✅ Preserves .title font, applies italic style
    /// ```
    func italic() -> some View {
        // Use a ViewModifier that reads the current font from environment
        // and applies italic to it, preserving the existing font choice
        // This is the standard SwiftUI approach for preserving environment values
        modifier(ItalicModifier())
    }
}

// MARK: - Italic ViewModifier

/// ViewModifier that applies italic styling while preserving the existing font
/// Uses @Environment to read the current font, which is the standard SwiftUI pattern
private struct ItalicModifier: ViewModifier {
    @Environment(\.font) private var currentFont
    
    func body(content: Content) -> some View {
        // If there's a font in the environment, apply italic to it
        // Otherwise, use default body font with italic
        let italicFont = currentFont?.italic() ?? Font.system(.body).italic()
        return content.font(italicFont)
    }
}
