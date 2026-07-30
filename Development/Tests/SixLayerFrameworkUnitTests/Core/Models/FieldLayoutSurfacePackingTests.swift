//
//  FieldLayoutSurfacePackingTests.swift
//  SixLayerFrameworkTests
//
//  DynamicForm / IntelligentForm (DataField) packing recipes used by
//  framework-owned packed layouts (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Layout Surface Packing")
struct FieldLayoutSurfacePackingTests {

    private let bands = FieldDisplayWidthPlatformBands(narrow: 120, medium: 180, wide: 320)

    @Test func packedFormControlLeadingInset_labelAbove_isZero() {
        #expect(FieldLayoutAligner.packedFormFieldArrangement == .labelAbove)
        #expect(FieldLayoutAligner.packedFormControlLeadingInset(labelWidths: [40, 120], labelControlSpacing: 8) == 0)
    }

    @Test func packedSectionPlan_includesZeroLeadingInsetAndColumnWidths() {
        let items = [
            FieldLayoutPackItem(id: "a", kind: .checkbox, preferredWidth: 80),
            FieldLayoutPackItem(id: "b", kind: .checkbox, preferredWidth: 100),
            FieldLayoutPackItem(id: "c", kind: .checkbox, preferredWidth: 90)
        ]
        // 80+10+100 = 190 fits; +10+90 = 290 > 250 → two rows
        let plan = FieldLayoutPackedSection.plan(
            items: items,
            availableWidth: 250,
            spacing: 10,
            maxItemsPerRow: 4
        )
        #expect(plan.rows.count == 2)
        #expect(plan.rows[0].map(\.id) == ["a", "b"])
        #expect(plan.rows[1].map(\.id) == ["c"])
        #expect(plan.columnWidths == [90, 100])
        #expect(plan.controlLeadingInset == 0)
    }

    @Test func dynamicForm_checkboxRun_packsSideBySideUnderAvailableWidth() {
        let fields = (0..<4).map { i in
            DynamicFormField(
                id: "c\(i)",
                contentType: .checkbox,
                label: "C\(i)",
                metadata: ["displayWidth": "narrow"]
            )
        }
        let items = fields.map { $0.layoutPackItem(bands: bands, availableWidth: 528) }
        let plan = FieldLayoutPackedSection.plan(
            items: items,
            availableWidth: 528,
            spacing: 16,
            maxItemsPerRow: 4
        )
        #expect(items.allSatisfy { $0.kind == .checkbox })
        #expect(items.allSatisfy { $0.preferredWidth == 120 })
        #expect(plan.rows.count == 1)
        #expect(plan.rows[0].count == 4)
        #expect(plan.controlLeadingInset == 0)
    }

    @Test func dynamicForm_narrowFields_capAndPackRespectAvailableWidth() {
        let fields = (0..<3).map { i in
            DynamicFormField(
                id: "n\(i)",
                contentType: .text,
                label: "N\(i)",
                metadata: ["displayWidth": "narrow"]
            )
        }
        let items = fields.map { $0.layoutPackItem(bands: bands, availableWidth: 200) }
        let plan = FieldLayoutPackedSection.plan(
            items: items,
            availableWidth: 200,
            spacing: 16,
            maxItemsPerRow: 4
        )
        #expect(items.allSatisfy { $0.preferredWidth == 120 })
        // 120+16+120 = 256 > 200 → one per row
        #expect(plan.rows.count == 3)
        #expect(plan.rows.allSatisfy { $0.count == 1 })
    }

    @Test func dataField_booleanRun_packsLikeIntelligentFormSurface() {
        let fields = (0..<3).map { i in
            DataField(name: "flag\(i)", type: .boolean)
        }
        let hints = FieldDisplayHints(displayWidth: "narrow")
        let items = fields.map {
            $0.layoutPackItem(hints: hints, bands: bands, availableWidth: 400)
        }
        let plan = FieldLayoutPackedSection.plan(
            items: items,
            availableWidth: 400,
            spacing: 16,
            maxItemsPerRow: 4
        )
        #expect(items.allSatisfy { $0.kind == .checkbox })
        #expect(plan.rows.count == 1)
        #expect(plan.rows[0].count == 3)
        #expect(plan.columnWidths.first == 120)
        #expect(plan.controlLeadingInset == 0)
    }
}
