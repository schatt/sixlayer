//
//  OCRStructuredExtractionFollowups283Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Follow-up structured extraction (#283–#287).
//

import CoreGraphics
import Foundation
import Testing
@testable import SixLayerFramework

@Suite("OCR structured extraction follow-ups (#283–#287)", .serialized)
struct OCRStructuredExtractionFollowups283Tests {

    private let service = OCRService()

    // MARK: #283 — calculation-group field names

    @Test func jointDecimalCorrection_usesFuelCostAndVolumeFieldNames() throws {
        let (modelName, cleanup) = try createAliasFuelHintsFile()
        defer { try? cleanup() }

        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        let text = "This Sale 3726 Volume 6.775"

        let pipeline = structuredPipeline(from: text, context: context)

        let fuelCost = doubleValue(pipeline.structuredData["fuelCost"])
        let volume = doubleValue(pipeline.structuredData["volume"])
        #expect(fuelCost != nil)
        #expect(volume != nil)
        #expect(abs((fuelCost ?? 0) - 37.26) < 0.02)
        #expect(abs((volume ?? 0) - 6.775) < 0.001)
    }

    // MARK: #284 — printed PPG

    @Test func jointDecimalCorrection_prefersPairMatchingPrintedPPG() throws {
        let (modelName, cleanup) = try createPumpFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = pumpOCRContext(entityName: modelName)
        let text = "This Sale 3726 Gallons 6.775 Price per gallon 5.50"

        let pipeline = structuredPipeline(from: text, context: context)

        let total = doubleValue(pipeline.structuredData["totalCost"])
        let gallons = doubleValue(pipeline.structuredData["gallons"])
        #expect(total != nil)
        #expect(gallons != nil)
        #expect(abs((total ?? 0) - 37.26) < 0.02)
        let implied = (total ?? 0) / (gallons ?? 1)
        #expect(abs(implied - 5.50) < 0.05)
    }

    // MARK: #286 — fail closed

    @Test func jointDecimalCorrection_flagsFailureWithoutPerFieldOverride() throws {
        let (modelName, cleanup) = try createTightRangeFuelHintsFile()
        defer { try? cleanup() }

        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        let text = "This Sale 5000 Gallons 5000"

        let pipeline = structuredPipeline(from: text, context: context)

        let adjustment = pipeline.adjustedFields["totalCost"] ?? ""
        #expect(adjustment.contains("no retail-plausible pair"))
        #expect(pipeline.structuredData["totalCost"] == "5000")
        #expect(pipeline.extractionConfidence <= 0.5)
    }

    // MARK: #285 — layout

    @Test func labelAnchoring_collectsGallonsFromLineAndFlatText() {
        let patterns = [
            "gallons": "(?i)((gallons)\\s*[:=]?\\s*([\\d.,]+)|([\\d.,]+)\\s+(gallons))"
        ]
        let lineCandidates = OCRLabelAnchoredExtraction.collectCandidates(
            in: "Gallons 6.775",
            patterns: patterns,
            recognitionLines: nil
        )
        let flatCandidates = OCRLabelAnchoredExtraction.collectCandidates(
            in: "3726 Gallons This Sale 6.775",
            patterns: patterns,
            recognitionLines: nil
        )
        #expect(lineCandidates.contains { $0.fieldId == "gallons" && $0.value == "6.775" })
        #expect(flatCandidates.contains { $0.fieldId == "gallons" && $0.value == "3726" })
    }

    @Test func labelAnchoring_prefersLayoutProximityOverShuffledFlatText() {
        let patterns = [
            "totalCost": "(?i)((this sale|sale)\\s*[:=]?\\s*([\\d.,]+)|([\\d.,]+)\\s+(this sale|sale))",
            "gallons": "(?i)((gallons)\\s*[:=]?\\s*([\\d.,]+)|([\\d.,]+)\\s+(gallons))"
        ]
        let flatText = "3726 Gallons This Sale 6.775"
        let lines = [
            OCRRecognitionLine(text: "This Sale 3726", boundingBox: CGRect(x: 0, y: 0.8, width: 0.5, height: 0.1)),
            OCRRecognitionLine(text: "Gallons 6.775", boundingBox: CGRect(x: 0, y: 0.2, width: 0.5, height: 0.1))
        ]

        let withLayout = OCRLabelAnchoredExtraction.extract(
            from: flatText,
            patterns: patterns,
            recognitionLines: lines
        )
        let stringOnly = OCRLabelAnchoredExtraction.extract(
            from: flatText,
            patterns: patterns,
            recognitionLines: nil
        )

        #expect(withLayout["totalCost"] == "3726")
        #expect(withLayout["gallons"] == "6.775")
        #expect(stringOnly["totalCost"] == "6.775")
        #expect(stringOnly["gallons"] == "3726")
    }

    // MARK: #287 — locale decimal comma

    @Test func jointDecimalCorrection_parsesCommaDecimalVolume() throws {
        let (modelName, cleanup) = try createPumpFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = OCRContext(
            textTypes: [.price, .number],
            language: .french,
            extractionMode: .automatic,
            entityName: modelName
        )
        let text = "This Sale 2000 Gallons 3,704"

        let pipeline = structuredPipeline(from: text, context: context)

        let total = doubleValue(pipeline.structuredData["totalCost"])
        let gallons = doubleValue(pipeline.structuredData["gallons"])
        #expect(abs((total ?? 0) - 20.00) < 0.02)
        #expect(abs((gallons ?? 0) - 3.704) < 0.001)
    }

    // MARK: - Helpers

    private func pumpOCRContext(entityName: String) -> OCRContext {
        OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: entityName
        )
    }

    private func structuredPipeline(from extractedText: String, context: OCRContext) -> (
        structuredData: [String: String],
        adjustedFields: [String: String],
        extractionConfidence: Float
    ) {
        let base = OCRResult(
            extractedText: extractedText,
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0,
            language: context.language
        )
        let pipeline = service.applyStructuredExtraction(from: base, context: context)
        return (pipeline.structuredData, pipeline.adjustedFields, pipeline.extractionConfidence)
    }

    private func doubleValue(_ string: String?) -> Double? {
        guard let string else { return nil }
        return Double(string.replacingOccurrences(of: ",", with: "."))
    }

    private func createPumpFuelPurchaseHintsFile() throws -> (modelName: String, cleanup: () throws -> Void) {
        try writeHintsFile(named: "FuelPurchasePump283", json: pumpHintsJSON(
            productKey: "totalCost",
            volumeKey: "gallons",
            rateKey: "pricePerGallon"
        ))
    }

    private func createAliasFuelHintsFile() throws -> (modelName: String, cleanup: () throws -> Void) {
        try writeHintsFile(named: "FuelPurchaseAlias283", json: pumpHintsJSON(
            productKey: "fuelCost",
            volumeKey: "volume",
            rateKey: "unitRate"
        ))
    }

    private func createTightRangeFuelHintsFile() throws -> (modelName: String, cleanup: () throws -> Void) {
        var json = pumpHintsJSON(productKey: "totalCost", volumeKey: "gallons", rateKey: "pricePerGallon")
        if var total = json["totalCost"] as? [String: Any] {
            total["expectedRange"] = ["min": 1.0, "max": 5.0]
            json["totalCost"] = total
        }
        if var gallons = json["gallons"] as? [String: Any] {
            gallons["expectedRange"] = ["min": 0.1, "max": 0.5]
            json["gallons"] = gallons
        }
        return try writeHintsFile(named: "FuelPurchaseTight286", json: json)
    }

    private func pumpHintsJSON(productKey: String, volumeKey: String, rateKey: String) -> [String: Any] {
        let group: [[String: Any]] = [
            [
                "id": "fuel_purchase_relationship",
                "formula": "\(productKey) = \(rateKey) * \(volumeKey)",
                "dependentFields": [rateKey, volumeKey],
                "priority": 1
            ]
        ]
        return [
            productKey: [
                "ocrHints": ["this sale", "sale", "total", "$"],
                "expectedRange": ["min": 5.0, "max": 300.0],
                "calculationGroups": group
            ],
            volumeKey: [
                "ocrHints": ["gallons", "volume", "quantity"],
                "expectedRange": ["min": 0.5, "max": 40.0],
                "calculationGroups": [
                    [
                        "id": "fuel_purchase_relationship",
                        "formula": "\(volumeKey) = \(productKey) / \(rateKey)",
                        "dependentFields": [productKey, rateKey],
                        "priority": 1
                    ]
                ]
            ],
            rateKey: [
                "ocrHints": ["price per gallon", "per gallon"],
                "expectedRange": ["min": 2.0, "max": 10.0],
                "calculationGroups": [
                    [
                        "id": "fuel_purchase_relationship",
                        "formula": "\(rateKey) = \(productKey) / \(volumeKey)",
                        "dependentFields": [productKey, volumeKey],
                        "priority": 1
                    ]
                ]
            ]
        ]
    }

    private func writeHintsFile(named prefix: String, json: [String: Any]) throws -> (String, () throws -> Void) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1)
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let modelName = "\(prefix)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(modelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        return (modelName, { try fileManager.removeItem(at: testFile) })
    }
}
