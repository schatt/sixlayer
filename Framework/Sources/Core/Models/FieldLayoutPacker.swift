//
//  FieldLayoutPacker.swift
//  SixLayerFramework
//
//  Shared field packing for framework-owned layouts (GitHub #385).
//

import CoreGraphics
import Foundation

/// Coarse layout kind used by ``FieldLayoutPacker`` for run affinity and isolation.
public enum FieldLayoutPackKind: String, Sendable, Equatable {
    /// Short single-line controls (text, number, picker, etc.).
    case compact
    /// Checkbox / toggle-style intrinsic controls (same-type run affinity).
    case checkbox
    /// Multi-line / tall content — always alone on a row.
    case tall
    /// Wide flexible content that should not share a row with a compact strip.
    case wideFlex
}

/// One field participating in section packing.
public struct FieldLayoutPackItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let kind: FieldLayoutPackKind
    /// Preferred horizontal claim; `nil` means flexible within the row/window.
    public let preferredWidth: CGFloat?

    public init(id: String, kind: FieldLayoutPackKind, preferredWidth: CGFloat?) {
        self.id = id
        self.kind = kind
        self.preferredWidth = preferredWidth
    }
}

/// Pure packer: author order, width-aware rows, same-type runs, tall/wide isolation.
public enum FieldLayoutPacker {
    /// Packs `items` into rows. Does not reorder globally by kind.
    public static func pack(
        _ items: [FieldLayoutPackItem],
        availableWidth: CGFloat,
        spacing: CGFloat,
        maxItemsPerRow: Int
    ) -> [[FieldLayoutPackItem]] {
        // DELIBERATE RED stub (#385): one field per row — wrong until green.
        _ = (availableWidth, spacing, maxItemsPerRow)
        return items.map { [$0] }
    }
}
