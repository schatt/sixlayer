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

/// How a control sits inside its preferred-width field claim (GitHub #385).
public enum FieldLayoutControlSizing: String, Sendable, Equatable {
    /// Text-like controls fill the preferred-width slot.
    case fillClaim
    /// Intrinsic controls (checkbox / toggle) stay content-sized within the claim.
    case intrinsicWithinClaim

    /// Maps pack kind → how the control fills its preferred-width claim.
    public static func forPackKind(_ kind: FieldLayoutPackKind) -> FieldLayoutControlSizing {
        switch kind {
        case .checkbox:
            return .intrinsicWithinClaim
        case .compact, .tall, .wideFlex:
            return .fillClaim
        }
    }
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
    /// Packs `items` into rows without reordering.
    ///
    /// Rules:
    /// - Preserve author order
    /// - Keep contiguous same-`kind` runs together (never glue run tail to a different kind)
    /// - `tall` and `wideFlex` always occupy their own row
    /// - Respect `availableWidth`, `spacing`, and `maxItemsPerRow`
    public static func pack(
        _ items: [FieldLayoutPackItem],
        availableWidth: CGFloat,
        spacing: CGFloat,
        maxItemsPerRow: Int
    ) -> [[FieldLayoutPackItem]] {
        var rows: [[FieldLayoutPackItem]] = []
        var index = 0
        let maxPerRow = max(1, maxItemsPerRow)

        while index < items.count {
            let item = items[index]

            if item.kind == .tall || item.kind == .wideFlex {
                rows.append([item])
                index += 1
                continue
            }

            // Flexible (nil preferred): alone on a row; do not merge into a multi-field strip.
            if item.preferredWidth == nil {
                rows.append([item])
                index += 1
                continue
            }

            var row: [FieldLayoutPackItem] = []
            var usedWidth: CGFloat = 0
            let runKind = item.kind

            while index < items.count {
                let candidate = items[index]
                guard candidate.kind == runKind else { break }
                guard candidate.kind != .tall, candidate.kind != .wideFlex else { break }

                guard let width = candidate.preferredWidth else {
                    // Next in run is flexible — flush current row first; flexible handled next iteration.
                    break
                }

                if row.isEmpty {
                    row.append(candidate)
                    usedWidth = width
                    index += 1
                    continue
                }

                if row.count >= maxPerRow { break }
                if usedWidth + spacing + width > availableWidth { break }

                row.append(candidate)
                usedWidth += spacing + width
                index += 1
            }

            if !row.isEmpty {
                rows.append(row)
            }
        }

        return rows
    }
}
