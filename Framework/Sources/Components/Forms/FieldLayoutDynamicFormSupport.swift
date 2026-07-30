//
//  FieldLayoutDynamicFormSupport.swift
//  SixLayerFramework
//
//  Bridge DynamicFormField → FieldLayoutPacker (GitHub #385).
//

import CoreGraphics
import Foundation

public extension DynamicFormField {
    /// Layout kind for shared packing (same-type runs, tall/wide isolation).
    var layoutPackKind: FieldLayoutPackKind {
        switch contentType ?? .text {
        case .checkbox, .toggle, .boolean:
            return .checkbox
        case .textarea, .richtext:
            return .tall
        default:
            if displayHints?.isWide == true {
                return .wideFlex
            }
            return .compact
        }
    }

    /// Preferred width claim from ``FieldDisplayHints`` using the shared resolver.
    func preferredLayoutWidth(
        hints: FieldDisplayHints? = nil,
        characterWidth: CGFloat = FieldDisplayCharacterMetrics.averageCharacterWidth(),
        horizontalPadding: CGFloat = FieldDisplayCharacterMetrics.defaultHorizontalPadding,
        bands: FieldDisplayWidthPlatformBands = .forPlatform(SixLayerPlatform.current),
        availableWidth: CGFloat? = nil
    ) -> CGFloat? {
        FieldDisplayWidthResolver.preferredWidth(
            hints: hints ?? displayHints,
            characterWidth: characterWidth,
            horizontalPadding: horizontalPadding,
            bands: bands,
            availableWidth: availableWidth
        )
    }

    /// Packer input for this field.
    func layoutPackItem(
        hints: FieldDisplayHints? = nil,
        bands: FieldDisplayWidthPlatformBands = .forPlatform(SixLayerPlatform.current),
        availableWidth: CGFloat? = nil
    ) -> FieldLayoutPackItem {
        FieldLayoutPackItem(
            id: id,
            kind: layoutPackKind,
            preferredWidth: preferredLayoutWidth(
                hints: hints,
                bands: bands,
                availableWidth: availableWidth
            )
        )
    }
}
