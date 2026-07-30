//
//  FieldLayoutDataFieldSupport.swift
//  SixLayerFramework
//
//  Bridge DataField (+ hints) → FieldLayoutPacker (GitHub #385).
//

import CoreGraphics
import Foundation

public extension DataField {
    /// Layout kind for shared packing given optional display hints.
    func layoutPackKind(hints: FieldDisplayHints?) -> FieldLayoutPackKind {
        switch type {
        case .boolean:
            return .checkbox
        case .image, .document:
            return .tall
        default:
            if hints?.isWide == true {
                return .wideFlex
            }
            return .compact
        }
    }

    /// Preferred width claim from hints using the shared resolver.
    func preferredLayoutWidth(
        hints: FieldDisplayHints?,
        characterWidth: CGFloat = FieldDisplayCharacterMetrics.averageCharacterWidth(),
        horizontalPadding: CGFloat = FieldDisplayCharacterMetrics.defaultHorizontalPadding,
        bands: FieldDisplayWidthPlatformBands = .forPlatform(SixLayerPlatform.current),
        availableWidth: CGFloat? = nil
    ) -> CGFloat? {
        FieldDisplayWidthResolver.preferredWidth(
            hints: hints,
            characterWidth: characterWidth,
            horizontalPadding: horizontalPadding,
            bands: bands,
            availableWidth: availableWidth
        )
    }

    /// Packer input for this introspection field.
    func layoutPackItem(
        hints: FieldDisplayHints?,
        bands: FieldDisplayWidthPlatformBands = .forPlatform(SixLayerPlatform.current)
    ) -> FieldLayoutPackItem {
        FieldLayoutPackItem(
            id: name,
            kind: layoutPackKind(hints: hints),
            preferredWidth: preferredLayoutWidth(hints: hints, bands: bands)
        )
    }
}
