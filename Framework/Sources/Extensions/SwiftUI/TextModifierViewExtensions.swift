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
    /// On Text views, it applies bold font weight.
    /// On container views (VStack, etc.), it propagates to children via environment.
    /// On non-text views (Image, Shape), it has no visible effect but doesn't error.
    ///
    /// - Returns: A view with bold font weight applied (or unchanged if not applicable)
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Hello")
    ///     .basicAutomaticCompliance()
    ///     .bold()  // ✅ Works via View extension
    /// ```
    func bold() -> some View {
        self.fontWeight(.bold)
    }
    
    /// Apply italic style to any View
    /// 
    /// This extension replicates Text's `.italic()` modifier for all Views.
    /// Uses `.font()` with an italic font to apply italic styling.
    /// On Text views, it applies italic style.
    /// On container views (VStack, etc.), it propagates to children via environment.
    /// On non-text views (Image, Shape), it has no visible effect but doesn't error.
    ///
    /// - Returns: A view with italic style applied (or unchanged if not applicable)
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Hello")
    ///     .basicAutomaticCompliance()
    ///     .italic()  // ✅ Works via View extension
    /// ```
    func italic() -> some View {
        // Use .font() with an italic font to apply italic styling
        // Font.italic() returns an italic version of the font
        // This works for Text views and propagates via environment to children
        // For non-text views, this has no visible effect (expected behavior)
        self.font(.system(.body).italic())
    }
}
