//
//  AllowsNegativeKeyboardTests.swift
//  SixLayerFramework
//
//  Issue #548: opt-in signed keyboard for number and integer fields.
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Allows Negative Keyboard")
struct AllowsNegativeKeyboardTests {

    @Test(arguments: [
        (NumericFieldKind.number, false, PlatformKeyboardType.decimalPad),
        (NumericFieldKind.integer, false, PlatformKeyboardType.numberPad),
        (NumericFieldKind.number, true, PlatformKeyboardType.numbersAndPunctuation),
        (NumericFieldKind.integer, true, PlatformKeyboardType.numbersAndPunctuation)
    ])
    func keyboardChoice(kind: NumericFieldKind, allowsNegative: Bool, expected: PlatformKeyboardType) {
        #expect(NumericFieldKeyboard.keyboardType(kind: kind, allowsNegative: allowsNegative) == expected)
    }

    @Test func displayHintsReadsStoredTrue() {
        let field = DynamicFormField(
            id: "surcharge",
            contentType: .number,
            label: "Surcharge",
            metadata: ["allowsNegative": "true"]
        )
        #expect(field.displayHints?.allowsNegative == true)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: field.displayHints?.allowsNegative == true
            ) == .numbersAndPunctuation
        )
    }

    @Test(arguments: ["false", "TRUE", "yes", "1"])
    func displayHintsTreatsNonTrueStoredValuesAsOff(stored: String) {
        let field = DynamicFormField(
            id: "surcharge",
            contentType: .number,
            label: "Surcharge",
            metadata: ["allowsNegative": stored]
        )
        #expect(field.displayHints?.allowsNegative == false)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: field.displayHints?.allowsNegative == true
            ) == .decimalPad
        )
    }

    @Test func omittedMetadataStaysOnDecimalPad() {
        let field = DynamicFormField(
            id: "amount",
            contentType: .number,
            label: "Amount",
            metadata: ["displayWidth": "medium"]
        )
        #expect(field.displayHints?.allowsNegative == false)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: field.displayHints?.allowsNegative == true
            ) == .decimalPad
        )
    }

    @Test func hintsFileBoolTrueSurvivesLoadAndApply() throws {
        let (fileURL, modelName) = try HintsTestFixtures.writeHintsFile(
            modelName: "Surcharge_boolTrue",
            json: [
                "surcharge": [
                    "fieldType": "number",
                    "allowsNegative": true
                ]
            ]
        )
        defer { HintsTestFixtures.cleanup(fileURL) }

        let loaded = HintsTestFixtures.loader(for: fileURL).loadHintsResult(for: modelName).fieldHints["surcharge"]
        #expect(loaded?.allowsNegative == true)
        #expect(loaded?.metadata["allowsNegative"] == nil)

        let merged = numberField(metadata: nil).applying(hints: loaded!)
        #expect(merged.metadata?["allowsNegative"] == "true")
        #expect(merged.displayHints?.allowsNegative == true)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: merged.displayHints?.allowsNegative == true
            ) == .numbersAndPunctuation
        )
    }

    @Test func hintsFileStringTrueSurvivesLoadAndApply() throws {
        let (fileURL, modelName) = try HintsTestFixtures.writeHintsFile(
            modelName: "Surcharge_stringTrue",
            json: [
                "surcharge": [
                    "fieldType": "number",
                    "allowsNegative": "true"
                ]
            ]
        )
        defer { HintsTestFixtures.cleanup(fileURL) }

        let loaded = HintsTestFixtures.loader(for: fileURL).loadHintsResult(for: modelName).fieldHints["surcharge"]
        #expect(loaded?.allowsNegative == true)
        #expect(loaded?.metadata["allowsNegative"] == nil)

        let merged = numberField(metadata: nil).applying(hints: loaded!)
        #expect(merged.metadata?["allowsNegative"] == "true")
    }

    @Test(arguments: ["false", "yes", "1"])
    func hintsFileNonTrueValuesStayOff(raw: String) throws {
        let (fileURL, modelName) = try HintsTestFixtures.writeHintsFile(
            modelName: "Surcharge_nonTrue_\(raw)",
            json: [
                "surcharge": [
                    "fieldType": "number",
                    "allowsNegative": raw
                ]
            ]
        )
        defer { HintsTestFixtures.cleanup(fileURL) }

        let loaded = HintsTestFixtures.loader(for: fileURL).loadHintsResult(for: modelName).fieldHints["surcharge"]
        #expect(loaded?.allowsNegative == false)

        let merged = numberField(metadata: nil).applying(hints: loaded!)
        #expect(merged.displayHints?.allowsNegative == false)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .integer,
                allowsNegative: merged.displayHints?.allowsNegative == true
            ) == .numberPad
        )
    }

    @Test func omittedHintsKeyStaysOnThePad() throws {
        let (fileURL, modelName) = try HintsTestFixtures.writeHintsFile(
            modelName: "Surcharge_omitted",
            json: [
                "amount": [
                    "fieldType": "number"
                ]
            ]
        )
        defer { HintsTestFixtures.cleanup(fileURL) }

        let loaded = HintsTestFixtures.loader(for: fileURL).loadHintsResult(for: modelName).fieldHints["amount"]
        #expect(loaded?.allowsNegative == false)

        let merged = numberField(metadata: nil).applying(hints: loaded!)
        #expect(merged.displayHints?.allowsNegative != true)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: merged.displayHints?.allowsNegative == true
            ) == .decimalPad
        )
    }

    @Test func existingMetadataWinsOverHints() throws {
        let (fileURL, modelName) = try HintsTestFixtures.writeHintsFile(
            modelName: "Surcharge_existingMetadata",
            json: [
                "surcharge": [
                    "fieldType": "number",
                    "allowsNegative": true
                ]
            ]
        )
        defer { HintsTestFixtures.cleanup(fileURL) }

        let loaded = HintsTestFixtures.loader(for: fileURL).loadHintsResult(for: modelName).fieldHints["surcharge"]
        #expect(loaded?.allowsNegative == true)

        let merged = numberField(metadata: ["allowsNegative": "false"]).applying(hints: loaded!)
        #expect(merged.metadata?["allowsNegative"] == "false")
        #expect(merged.displayHints?.allowsNegative == false)
        #expect(
            NumericFieldKeyboard.keyboardType(
                kind: .number,
                allowsNegative: merged.displayHints?.allowsNegative == true
            ) == .decimalPad
        )
    }

    @Test func jsonFieldHintsStoreKeepsAllowsNegative() throws {
        let store = JSONFieldHintsStore(baseURL: FileManager.default.temporaryDirectory)
        let formId = "allowsNegative_\(UUID().uuidString)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(formId)_hints.json")
        defer { HintsTestFixtures.cleanup(fileURL) }

        try store.saveHints(
            [
                "surcharge": FieldDisplayHints(fieldType: "number", allowsNegative: true),
                "quantity": FieldDisplayHints(fieldType: "integer", allowsNegative: false)
            ],
            formId: formId
        )

        let loaded = store.loadHints(formId: formId)
        #expect(loaded["surcharge"]?.allowsNegative == true)
        #expect(loaded["quantity"]?.allowsNegative == false)
    }

    private func numberField(metadata: [String: String]?) -> DynamicFormField {
        DynamicFormField(
            id: "surcharge",
            contentType: .number,
            label: "Surcharge",
            metadata: metadata
        )
    }

}
