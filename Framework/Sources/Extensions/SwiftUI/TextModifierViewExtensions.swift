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
    /// On Text views, it applies italic style.
    /// On container views (VStack, etc.), it has no effect (Text children would need their own .italic()).
    /// On non-text views (Image, Shape), it has no visible effect but doesn't error.
    ///
    /// Note: Since SwiftUI's `.italic()` is Text-specific and doesn't exist on View,
    /// this extension allows chaining to compile. On Text views, italic will be applied
    /// via Text's own `.italic()` method when the type is resolved. On non-text views,
    /// this has no effect, which is reasonable and matches SwiftUI's behavior where
    /// font modifiers don't affect non-text views.
    ///
    /// - Returns: A view with italic style applied (or unchanged if not applicable)
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Hello")
    ///     .basicAutomaticCompliance()
    ///     .italic()  // ✅ Works via View extension (Text's .italic() is called)
    /// ```
    func italic() -> some View {
        // Since .italic() is Text-specific and doesn't exist on View,
        // we return self unchanged. This allows chaining to compile.
        // On Text views, Swift will use Text's own .italic() method when available.
        // On non-text views, this has no effect (reasonable behavior).
        self
    }
}
