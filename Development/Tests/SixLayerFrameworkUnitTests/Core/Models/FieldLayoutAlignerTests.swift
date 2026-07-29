//
//  FieldLayoutAlignerTests.swift
//  SixLayerFrameworkTests
//
//  Shared control / column alignment for packed field layouts (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Layout Aligner")
struct FieldLayoutAlignerTests {

    private func item(
        id: String,
        kind: FieldLayoutPackKind = .compact,
        preferredWidth: CGFloat?
    ) -> FieldLayoutPackItem {
        FieldLayoutPackItem(id: id, kind: kind, preferredWidth: preferredWidth)
    }

    @Test func columnMaxWidths_alignsSameIndexAcrossRows() {
        let rows: [[FieldLayoutPackItem]] = [
            [item(id: "a", preferredWidth: 80), item(id: "b", preferredWidth: 120)],
            [item(id: "c", preferredWidth: 100), item(id: "d", preferredWidth: 90)]
        ]
        let widths = FieldLayoutAligner.columnMaxWidths(rows: rows)
        #expect(widths == [100, 120])
    }

    @Test func columnMaxWidths_handlesUnevenRowLengths() {
        let rows: [[FieldLayoutPackItem]] = [
            [item(id: "a", preferredWidth: 80), item(id: "b", preferredWidth: 120), item(id: "c", preferredWidth: 60)],
            [item(id: "d", preferredWidth: 100)]
        ]
        let widths = FieldLayoutAligner.columnMaxWidths(rows: rows)
        #expect(widths == [100, 120, 60])
    }

    @Test func columnMaxWidths_nilPreferredUsesZeroForMax() {
        let rows: [[FieldLayoutPackItem]] = [
            [item(id: "a", preferredWidth: nil), item(id: "b", preferredWidth: 50)],
            [item(id: "c", preferredWidth: 40), item(id: "d", preferredWidth: nil)]
        ]
        let widths = FieldLayoutAligner.columnMaxWidths(rows: rows)
        #expect(widths == [40, 50])
    }

    @Test func sharedControlLeadingInset_labelAbove_isZero() {
        let inset = FieldLayoutAligner.sharedControlLeadingInset(
            labelWidths: [40, 120, 80],
            labelControlSpacing: 8,
            arrangement: .labelAbove
        )
        #expect(inset == 0)
    }

    @Test func sharedControlLeadingInset_labelLeading_usesMaxLabelPlusSpacing() {
        let inset = FieldLayoutAligner.sharedControlLeadingInset(
            labelWidths: [40, 120, 80],
            labelControlSpacing: 8,
            arrangement: .labelLeading
        )
        #expect(inset == 128) // 120 + 8
    }

    @Test func sharedControlLeadingInset_emptyLabels_isZero() {
        let inset = FieldLayoutAligner.sharedControlLeadingInset(
            labelWidths: [],
            labelControlSpacing: 8,
            arrangement: .labelLeading
        )
        #expect(inset == 0)
    }
}
