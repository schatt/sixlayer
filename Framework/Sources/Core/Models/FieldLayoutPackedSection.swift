//
//  FieldLayoutPackedSection.swift
//  SixLayerFramework
//
//  Shared packing plan for framework-owned packed form layouts (GitHub #385).
//

import CoreGraphics
import Foundation

/// Result of packing fields for a form section: rows, column alignment, leading inset.
public struct FieldLayoutPackedSectionPlan: Sendable, Equatable {
    public let rows: [[FieldLayoutPackItem]]
    public let columnWidths: [CGFloat]
    /// Leading padding for each packed field (0 for label-above chrome).
    public let controlLeadingInset: CGFloat

    public init(
        rows: [[FieldLayoutPackItem]],
        columnWidths: [CGFloat],
        controlLeadingInset: CGFloat
    ) {
        self.rows = rows
        self.columnWidths = columnWidths
        self.controlLeadingInset = controlLeadingInset
    }
}

/// Builds the packing plan used by DynamicForm / IntelligentForm / GenericForm packed layouts.
public enum FieldLayoutPackedSection {
    /// Pack items, compute column max widths, and resolve the packed-form leading inset.
    public static func plan(
        items: [FieldLayoutPackItem],
        availableWidth: CGFloat,
        spacing: CGFloat,
        maxItemsPerRow: Int,
        labelWidths: [CGFloat] = [],
        labelControlSpacing: CGFloat = 8
    ) -> FieldLayoutPackedSectionPlan {
        let rows = FieldLayoutPacker.pack(
            items,
            availableWidth: availableWidth,
            spacing: spacing,
            maxItemsPerRow: maxItemsPerRow
        )
        return FieldLayoutPackedSectionPlan(
            rows: rows,
            columnWidths: FieldLayoutAligner.columnMaxWidths(rows: rows),
            controlLeadingInset: FieldLayoutAligner.packedFormControlLeadingInset(
                labelWidths: labelWidths,
                labelControlSpacing: labelControlSpacing
            )
        )
    }
}
