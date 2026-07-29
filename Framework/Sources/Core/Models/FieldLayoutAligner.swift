//
//  FieldLayoutAligner.swift
//  SixLayerFramework
//
//  Shared control / column alignment for packed field layouts (GitHub #385).
//

import CoreGraphics
import Foundation

/// How labels relate to controls in field chrome.
public enum FieldLabelControlArrangement: String, Sendable, Equatable {
    /// Label stacked above the control — controls already share a leading edge.
    case labelAbove
    /// Label beside the control — needs a shared control leading inset from max label width.
    case labelLeading
}

/// Pure alignment helpers for framework-owned field layouts.
public enum FieldLayoutAligner {
    /// Per-column max preferred width across packed rows so peer columns line up.
    ///
    /// Index `i` is the max of `preferredWidth` (treating `nil` as 0) for items at column `i`
    /// in every row. Uneven rows contribute only for columns they contain.
    public static func columnMaxWidths(rows: [[FieldLayoutPackItem]]) -> [CGFloat] {
        // DELIBERATE RED stub (#385)
        _ = rows
        return []
    }

    /// Shared leading inset for controls when labels sit beside them.
    ///
    /// - `labelAbove`: always `0` (controls already share the field leading edge).
    /// - `labelLeading`: `max(labelWidths) + labelControlSpacing`, or `0` if no labels.
    public static func sharedControlLeadingInset(
        labelWidths: [CGFloat],
        labelControlSpacing: CGFloat,
        arrangement: FieldLabelControlArrangement
    ) -> CGFloat {
        // DELIBERATE RED stub (#385)
        _ = (labelWidths, labelControlSpacing, arrangement)
        return -1
    }
}
