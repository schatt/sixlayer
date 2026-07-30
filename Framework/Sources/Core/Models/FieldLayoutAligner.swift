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
    /// Arrangement used by current packed form chrome (label stacked above the control).
    /// Label-leading chrome should switch this and supply measured `labelWidths`.
    public static let packedFormFieldArrangement: FieldLabelControlArrangement = .labelAbove

    /// Leading padding applied to each packed field for ``packedFormFieldArrangement``.
    /// Today always `0` (label-above); kept on the production path so label-leading can plug in.
    public static func packedFormControlLeadingInset(
        labelWidths: [CGFloat] = [],
        labelControlSpacing: CGFloat = 8
    ) -> CGFloat {
        sharedControlLeadingInset(
            labelWidths: labelWidths,
            labelControlSpacing: labelControlSpacing,
            arrangement: packedFormFieldArrangement
        )
    }

    /// Per-column max preferred width across packed rows so peer columns line up.
    ///
    /// Index `i` is the max of `preferredWidth` (treating `nil` as 0) for items at column `i`
    /// in every row. Uneven rows contribute only for columns they contain.
    public static func columnMaxWidths(rows: [[FieldLayoutPackItem]]) -> [CGFloat] {
        let columnCount = rows.map(\.count).max() ?? 0
        guard columnCount > 0 else { return [] }

        return (0..<columnCount).map { column in
            rows.reduce(CGFloat(0)) { partial, row in
                guard column < row.count else { return partial }
                let width = row[column].preferredWidth ?? 0
                return max(partial, width)
            }
        }
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
        switch arrangement {
        case .labelAbove:
            return 0
        case .labelLeading:
            guard let maxLabel = labelWidths.max() else { return 0 }
            return maxLabel + labelControlSpacing
        }
    }
}
