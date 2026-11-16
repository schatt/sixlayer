//
//  OCRFractionDigitFormatPriors678Tests.swift
//  SixLayerFrameworkTests
//
//  #678: regional fraction-digit / numeric format priors (distinct from fieldAverages).
//

@testable import SixLayerFramework
import Testing
import Foundation

@Suite("OCR fraction-digit format priors (#678)")
struct OCRFractionDigitFormatPriors678Tests {

    // MARK: - Hints / context shape

    @Test func fieldDisplayHintsStoresFractionDigits() {
        let hints = FieldDisplayHints(fractionDigits: 3)
        #expect(hints.fractionDigits == 3)
        #expect(FieldDisplayHints().fractionDigits == nil)
    }

    @Test func contextStoresFieldFractionDigitsOverride() {
        let context = OCRContext(fieldFractionDigits: ["gallons": 3])
        #expect(context.fieldFractionDigits?["gallons"] == 3)
        #expect(
            context.with(captureRegionCode: "US").fieldFractionDigits?["gallons"] == 3
        )
    }

    @Test func hintsFileResolvesDefaultFractionDigits() throws {
        let (modelName, cleanup) = try writeHintsFile([
            "gallons": [
                "expectedRange": ["min": 0.0, "max": 100.0],
                "fractionDigits": 3
            ]
        ])
        defer { cleanup() }

        let loader = FileBasedDataHintsLoader()
        let result = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "en"))
        #expect(result.fieldHints["gallons"]?.fractionDigits == 3)
    }

    @Test func hintsFilePrefersRegionKeyedFractionDigits() throws {
        let (modelName, cleanup) = try writeHintsFile([
            "gallons": [
                "expectedRange": ["min": 0.0, "max": 100.0],
                "fractionDigits": 2,
                "fractionDigits.US": 3,
                "fractionDigits.DE": 2
            ]
        ])
        defer { cleanup() }

        let loader = FileBasedDataHintsLoader()
        let us = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "en_US"))
        let de = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "de_DE"))
        #expect(us.fieldHints["gallons"]?.fractionDigits == 3)
        #expect(de.fieldHints["gallons"]?.fractionDigits == 2)
    }

    // MARK: - Decimal placement consumption

    /// "8022" with range 0…100 admits both 8.022 (3 places) and 80.22 (2 places).
    /// Mid-range preference alone favors 80.22; fractionDigits=3 must pick 8.022.
    @Test func fractionDigitPriorSteersDecimalPlacement() {
        let pipeline = runDecimalCorrection(
            raw: "8022",
            fieldId: "gallons",
            range: ValueRange(min: 0, max: 100),
            fieldFractionDigits: ["gallons": 3]
        )
        #expect(pipeline.structuredData["gallons"] == "8.022")
        #expect(pipeline.adjustedFields["gallons"] != nil)
    }

    @Test func absentFractionDigitPriorDoesNotForceThreePlaces() {
        // Same digits/range without a format prior: mid-range scoring prefers 80.22.
        let pipeline = runDecimalCorrection(
            raw: "8022",
            fieldId: "gallons",
            range: ValueRange(min: 0, max: 100),
            fieldFractionDigits: nil
        )
        #expect(pipeline.structuredData["gallons"] == "80.22")
    }

    @Test func contextOverrideBeatsHintsFileFractionDigits() throws {
        let (modelName, cleanup) = try writeHintsFile([
            "gallons": [
                "expectedRange": ["min": 0.0, "max": 100.0],
                "fractionDigits": 2,
                "ocrHints": ["gallons"]
            ]
        ])
        defer { cleanup() }

        let service = OCRService()
        let base = OCRResult(extractedText: "Gallons 8022", confidence: 1.0)
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionHints: ["gallons": #"Gallons\s+(\d+)"#],
            extractionMode: .custom,
            entityName: modelName,
            fieldRanges: ["gallons": ValueRange(min: 0, max: 100)],
            fieldFractionDigits: ["gallons": 3],
            decimalLocale: Locale(identifier: "en_US")
        )
        let pipeline = service.applyStructuredExtraction(from: base, context: context)
        #expect(pipeline.structuredData["gallons"] == "8.022")
    }

    // MARK: - Helpers

    private func runDecimalCorrection(
        raw: String,
        fieldId: String,
        range: ValueRange,
        fieldFractionDigits: [String: Int]?
    ) -> (
        structuredData: [String: String],
        adjustedFields: [String: String],
        extractionConfidence: Float,
        missingRequiredFields: [String]
    ) {
        let service = OCRService()
        let base = OCRResult(extractedText: "Gallons \(raw)", confidence: 1.0)
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionHints: [fieldId: #"Gallons\s+(\d+)"#],
            extractionMode: .custom,
            fieldRanges: [fieldId: range],
            fieldFractionDigits: fieldFractionDigits
        )
        return service.applyStructuredExtraction(from: base, context: context)
    }

    private func writeHintsFile(_ fields: [String: [String: Any]]) throws -> (String, () -> Void) {
        let fileManager = FileManager.default
        let documents = try #require(
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        )
        let hintsFolder = documents.appendingPathComponent("Hints", isDirectory: true)
        try fileManager.createDirectory(at: hintsFolder, withIntermediateDirectories: true)
        let modelName = "FractionDigit678_\(UUID().uuidString.prefix(8))"
        let url = hintsFolder.appendingPathComponent("\(modelName).hints")
        let data = try JSONSerialization.data(withJSONObject: fields, options: [.prettyPrinted])
        try data.write(to: url, options: .atomic)
        return (modelName, {
            try? fileManager.removeItem(at: url)
        })
    }
}
