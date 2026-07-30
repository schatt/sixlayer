//
//  FieldDisplayCharacterMetrics.swift
//  SixLayerFramework
//
//  Font-aware character width for expectedLength → points (GitHub #385).
//

import CoreGraphics
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Character metrics for converting ``FieldDisplayHints/expectedLength`` into points.
public enum FieldDisplayCharacterMetrics {
    /// Horizontal padding added when sizing from `expectedLength`.
    public static let defaultHorizontalPadding: CGFloat = 16

    /// Approximate average character width for a text style at a content size.
    ///
    /// Uses ``DynamicFontResolver`` platform fonts and measures a representative
    /// sample string so Dynamic Type / content-size scaling is reflected.
    public static func averageCharacterWidth(
        textStyle: SixLayerTextStyle = .body,
        contentSize: SixLayerContentSizeCategory = .large
    ) -> CGFloat {
        // DELIBERATE RED stub (#385)
        _ = (textStyle, contentSize)
        return 0
    }
}
