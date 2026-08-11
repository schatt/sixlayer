//
//  DisplayOCRSeparationTests.swift
//  SixLayerFrameworkTests
//
//  TDD for Issue #404: split batch OCR (supportsOCR) from Scan accessory (displayOCR).
//

import Testing
@testable import SixLayerFramework

@Suite("Display OCR Separation")
@MainActor
struct DisplayOCRSeparationTests {

    // MARK: - Defaults

    @Test func testDisplayOCRDefaultsToMatchSupportsOCRWhenOmitted() {
        let withoutOCR = DynamicFormField(id: "a", contentType: .text, label: "A")
        #expect(withoutOCR.supportsOCR == false)
        #expect(withoutOCR.displayOCR == false)

        let withOCR = DynamicFormField(
            id: "b",
            contentType: .text,
            label: "B",
            supportsOCR: true
        )
        #expect(withOCR.supportsOCR == true)
        #expect(withOCR.displayOCR == true)
    }

    // MARK: - Full matrix: batch vs Scan accessory

    @Test func testMatrixBatchAndDisplayShowsOCRAction() {
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons",
            supportsOCR: true,
            displayOCR: true
        )
        #expect(field.supportsOCR == true)
        #expect(field.displayOCR == true)
        #expect(hasOCRScanAction(field))
    }

    @Test func testMatrixBatchWithoutDisplayHidesOCRAction() {
        // CarManager station: receipt fill target, map trailingView only
        let field = DynamicFormField(
            id: "station",
            contentType: .text,
            label: "Station",
            supportsOCR: true,
            displayOCR: false,
            ocrHints: ["station", "fuel stop"]
        )
        #expect(field.supportsOCR == true)
        #expect(field.displayOCR == false)
        #expect(field.ocrHints?.count == 2)
        #expect(!hasOCRScanAction(field))
    }

    @Test func testMatrixDisplayWithoutBatchShowsOCRAction() {
        // Niche: per-field Scan without batch write
        let field = DynamicFormField(
            id: "vin",
            contentType: .text,
            label: "VIN",
            supportsOCR: false,
            displayOCR: true
        )
        #expect(field.supportsOCR == false)
        #expect(field.displayOCR == true)
        #expect(hasOCRScanAction(field))
    }

    @Test func testMatrixNeitherHidesOCRAction() {
        let field = DynamicFormField(
            id: "notes",
            contentType: .textarea,
            label: "Notes",
            supportsOCR: false,
            displayOCR: false
        )
        #expect(!hasOCRScanAction(field))
    }

    @Test func testGetOCREnabledFieldsUsesSupportsOCROnly() {
        let batchOnly = DynamicFormField(
            id: "station",
            contentType: .text,
            label: "Station",
            supportsOCR: true,
            displayOCR: false
        )
        let displayOnly = DynamicFormField(
            id: "vin",
            contentType: .text,
            label: "VIN",
            supportsOCR: false,
            displayOCR: true
        )
        let config = DynamicFormConfiguration(
            id: "fuel",
            title: "Fuel",
            sections: [
                DynamicFormSection(
                    id: "main",
                    title: "Main",
                    fields: [batchOnly, displayOnly]
                )
            ]
        )
        let enabledIds = Set(config.getOCREnabledFields().map(\.id))
        #expect(enabledIds == ["station"])
    }

    // MARK: - applying(hints:) must not infer flags from ocrHints

    @Test func testApplyingOCRHintsDoesNotEnableSupportsOCROrDisplayOCR() {
        let hints = FieldDisplayHints(ocrHints: ["station", "fuel stop"])
        let field = DynamicFormField(
            id: "station",
            contentType: .text,
            label: "Station",
            supportsOCR: false,
            displayOCR: false
        ).applying(hints: hints)

        #expect(field.ocrHints == ["station", "fuel stop"])
        #expect(field.supportsOCR == false)
        #expect(field.displayOCR == false)
        #expect(!hasOCRScanAction(field))
    }

    @Test func testApplyingOCRHintsPreservesExplicitBatchWithoutDisplay() {
        let hints = FieldDisplayHints(ocrHints: ["station"])
        let field = DynamicFormField(
            id: "station",
            contentType: .text,
            label: "Station",
            supportsOCR: true,
            displayOCR: false
        ).applying(hints: hints)

        #expect(field.ocrHints == ["station"])
        #expect(field.supportsOCR == true)
        #expect(field.displayOCR == false)
        #expect(!hasOCRScanAction(field))
    }

    @Test func testApplyingHintsCanSetSupportsOCRAndDisplayOCRWhenPresent() {
        let hints = FieldDisplayHints(
            ocrHints: ["gallons", "gal"],
            supportsOCR: true,
            displayOCR: false
        )
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons"
        ).applying(hints: hints)

        #expect(field.ocrHints == ["gallons", "gal"])
        #expect(field.supportsOCR == true)
        #expect(field.displayOCR == false)
        #expect(!hasOCRScanAction(field))
    }

    @Test func testApplyingHintsNilFlagsLeaveFieldUnchanged() {
        let hints = FieldDisplayHints(expectedLength: 10)
        let field = DynamicFormField(
            id: "x",
            contentType: .text,
            label: "X",
            supportsOCR: true,
            displayOCR: false
        ).applying(hints: hints)

        #expect(field.supportsOCR == true)
        #expect(field.displayOCR == false)
    }

    // MARK: - Helpers

    private func hasOCRScanAction(_ field: DynamicFormField) -> Bool {
        field.effectiveActions.contains { $0.id == "ocr-scan" }
    }
}
