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

    /// Sample used to estimate average glyph advance for proportional fonts.
    private static let sample = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    /// Approximate average character width for a text style at a content size.
    ///
    /// Uses ``DynamicFontResolver`` platform fonts and measures a representative
    /// sample string so Dynamic Type / content-size scaling is reflected.
    public static func averageCharacterWidth(
        textStyle: SixLayerTextStyle = .body,
        contentSize: SixLayerContentSizeCategory = .large
    ) -> CGFloat {
        let resolver = DynamicFontResolver(defaultContentSize: contentSize)
        #if os(iOS)
        let font = resolver.uiFont(for: textStyle, contentSize: contentSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (sample as NSString).size(withAttributes: attributes)
        return max(size.width / CGFloat(sample.count), 1)
        #elseif os(macOS)
        let font = resolver.nsFont(for: textStyle, contentSize: contentSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (sample as NSString).size(withAttributes: attributes)
        return max(size.width / CGFloat(sample.count), 1)
        #else
        _ = (resolver, textStyle)
        // Fallback when platform font metrics are unavailable.
        return 9
        #endif
    }
}
