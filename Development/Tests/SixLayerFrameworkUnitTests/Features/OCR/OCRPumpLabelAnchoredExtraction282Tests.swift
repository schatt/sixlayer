//
//  OCRPumpLabelAnchoredExtraction282Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Label-anchored pump LCD structured extraction (GitHub #282).
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("OCR pump label-anchored extraction (#282)")
struct OCRPumpLabelAnchoredExtraction282Tests {

    private let service = OCRService()

    // MARK: - Fixtures (issue #282)

    @Test func structuredData_IMG5145_labelAnchorsThisSaleAndGallons() throws {
        let (modelName, cleanup) = try createPumpFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = pumpOCRContext(entityName: modelName)
        let text = "This Sale 3726 Gallons 6.775 Price per gallon 5.50"

        let structured = try structuredData(from: text, context: context)

        let totalCost = doubleValue(structured["totalCost"])
        let gallons = doubleValue(structured["gallons"])

        #expect(totalCost != nil)
        #expect(gallons != nil)
        #expect(abs((totalCost ?? 0) - 37.26) < 0.02, "totalCost should be ~37.26, got \(structured["totalCost"] ?? "nil")")
        #expect(abs((gallons ?? 0) - 6.775) < 0.001, "gallons should be ~6.775, got \(structured["gallons"] ?? "nil")")
        if let gallonsValue = gallons {
            #expect(abs(gallonsValue - 3.726) > 0.01, "gallons must not be mis-bound sale digits 3.726")
        }
    }

    @Test func structuredData_IMG4997_repairsTenfoldSaleWhenImpliedPPGIsRetail() throws {
        let (modelName, cleanup) = try createPumpFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = pumpOCRContext(entityName: modelName)
        let text = "This Sale $ 2000 3.704 Gallons"

        let structured = try structuredData(from: text, context: context)

        let totalCost = doubleValue(structured["totalCost"])
        let gallons = doubleValue(structured["gallons"])

        #expect(abs((totalCost ?? 0) - 20.00) < 0.02, "totalCost should be ~20.00, got \(structured["totalCost"] ?? "nil")")
        #expect(abs((gallons ?? 0) - 3.704) < 0.001, "gallons should be ~3.704, got \(structured["gallons"] ?? "nil")")
    }

    @Test func structuredData_IMG5018_repairsSaleAndGallonsDecimals() throws {
        let (modelName, cleanup) = try createPumpFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = pumpOCRContext(entityName: modelName)
        let text = "This Sale $ 4354 7917 Gallons"

        let structured = try structuredData(from: text, context: context)

        let totalCost = doubleValue(structured["totalCost"])
        let gallons = doubleValue(structured["gallons"])

        #expect(abs((totalCost ?? 0) - 43.54) < 0.02, "totalCost should be ~43.54, got \(structured["totalCost"] ?? "nil")")
        #expect(abs((gallons ?? 0) - 7.917) < 0.001, "gallons should be ~7.917, got \(structured["gallons"] ?? "nil")")
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

    private func structuredData(from extractedText: String, context: OCRContext) throws -> [String: String] {
        let base = OCRResult(
            extractedText: extractedText,
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0,
            language: .english
        )
        return service.applyStructuredExtraction(from: base, context: context).structuredData
    }

    private func doubleValue(_ string: String?) -> Double? {
        guard let string else { return nil }
        return Double(string.replacingOccurrences(of: ",", with: ""))
    }

    /// Pump-style hints aligned with CarManager FuelPurchase.hints (issue #282).
    private func createPumpFuelPurchaseHintsFile() throws -> (modelName: String, cleanup: () throws -> Void) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)

        let uniqueModelName = "FuelPurchasePump282_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")

        let hintsJSON: [String: Any] = [
            "totalCost": [
                "ocrHints": ["this sale", "sale", "total", "amount due", "$"],
                "expectedRange": ["min": 5.0, "max": 300.0],
                "calculationGroups": [
                    [
                        "id": "fuel_purchase_relationship",
                        "formula": "totalCost = pricePerGallon * gallons",
                        "dependentFields": ["pricePerGallon", "gallons"],
                        "priority": 1
                    ]
                ]
            ],
            "gallons": [
                "ocrHints": ["gallons", "volume", "quantity"],
                "expectedRange": ["min": 0.5, "max": 40.0],
                "calculationGroups": [
                    [
                        "id": "fuel_purchase_relationship",
                        "formula": "gallons = totalCost / pricePerGallon",
                        "dependentFields": ["totalCost", "pricePerGallon"],
                        "priority": 1
                    ]
                ]
            ],
            "pricePerGallon": [
                "ocrHints": ["price per gallon", "per gallon", "price/gal"],
                "expectedRange": ["min": 2.0, "max": 10.0],
                "calculationGroups": [
                    [
                        "id": "fuel_purchase_relationship",
                        "formula": "pricePerGallon = totalCost / gallons",
                        "dependentFields": ["totalCost", "gallons"],
                        "priority": 1
                    ]
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: hintsJSON, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)

        let cleanup: () throws -> Void = {
            try fileManager.removeItem(at: testFile)
        }
        return (uniqueModelName, cleanup)
    }
}
