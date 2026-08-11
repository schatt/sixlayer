//
//  FieldHintsOCRExtensionTests.swift
//  SixLayerFrameworkTests
//
//  TDD Tests for OCR hints and calculation groups in .hints files
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Field Hints OCR Extensions")
struct FieldHintsOCRExtensionTests {
    
    /// Helper to create a loader that reads from documents directory
    private func createTestLoader() -> FileBasedDataHintsLoader {
        return FileBasedDataHintsLoader()
    }
    
    /// Helper to write a hints file to documents directory where loader can find it
    /// Uses unique filenames to ensure test isolation during parallel execution
    /// Returns both the file URL and the unique model name to use with loadHintsResult
    private func writeHintsFile(modelName: String, json: [String: Any]) throws -> (fileURL: URL, uniqueModelName: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        // Use unique filename to prevent conflicts during parallel test execution
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        // Verify file exists
        guard fileManager.fileExists(atPath: testFile.path) else {
            throw NSError(domain: "TestError", code: 2, userInfo: ["NSLocalizedDescription": "File was not created"])
        }
        return (testFile, uniqueModelName)
    }
    
    // MARK: - OCR Hints Parsing Tests
    
    @Test func testParseOCRHintsFromHintsFile() async throws {
        // Given: A hints file JSON with OCR hints
        let modelName = "FuelReceipt_testParseOCRHintsFromHintsFile"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "displayWidth": "medium",
                "ocrHints": ["gallons", "gal", "fuel quantity", "liters", "litres"]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing the hints (use unique model name from file)
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: OCR hints should be parsed
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 5)
        #expect(hints?.ocrHints?.contains("gallons") == true)
        #expect(hints?.ocrHints?.contains("gal") == true)
        #expect(hints?.ocrHints?.contains("fuel quantity") == true)
    }
    
    @Test func testParseOCRHintsAsStringArray() async throws {
        // Given: OCR hints as array in JSON
        let modelName = "Invoice_testParseOCRHintsAsStringArray"
        let json: [String: Any] = [
            "price": [
                "ocrHints": ["price", "cost", "amount", "$"]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse as array
        let hints = result.fieldHints["price"]
        #expect(hints?.ocrHints?.count == 4)
    }
    
    @Test func testParseOCRHintsAsCommaSeparatedString() async throws {
        // Given: OCR hints as comma-separated string (alternative format)
        let modelName = "Receipt_testParseOCRHintsAsCommaSeparatedString"
        let json: [String: Any] = [
            "total": [
                "ocrHints": "total,amount due,grand total"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Should parse and split by comma
        let hints = result.fieldHints["total"]
        #expect(hints?.ocrHints?.count == 3)
        #expect(hints?.ocrHints?.contains("total") == true)
        #expect(hints?.ocrHints?.contains("amount due") == true)
        #expect(hints?.ocrHints?.contains("grand total") == true)
    }
    
    @Test func testParseOCRHintsMissing() async throws {
        // Given: Field without OCR hints
        let modelName = "User_testParseOCRHintsMissing"
        let json: [String: Any] = [
            "username": [
                "expectedLength": "20"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: OCR hints should be nil
        let hints = result.fieldHints["username"]
        #expect(hints?.ocrHints == nil)
    }
    
    // MARK: - Calculation Groups Parsing Tests
    
    @Test func testParseCalculationGroupsFromHintsFile() async throws {
        // Given: A hints file with calculation groups
        let modelName = "Order_testParseCalculationGroupsFromHintsFile"
        let json: [String: Any] = [
            "total": [
                "calculationGroups": [
                    [
                        "id": "multiply",
                        "formula": "total = price * quantity",
                        "dependentFields": ["price", "quantity"],
                        "priority": 1
                    ]
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Calculation groups should be parsed
        let hints = result.fieldHints["total"]
        #expect(hints != nil)
        #expect(hints?.calculationGroups?.count == 1)
        #expect(hints?.calculationGroups?.first?.id == "multiply")
        #expect(hints?.calculationGroups?.first?.formula == "total = price * quantity")
        #expect(hints?.calculationGroups?.first?.dependentFields == ["price", "quantity"])
        #expect(hints?.calculationGroups?.first?.priority == 1)
    }
    
    @Test func testParseMultipleCalculationGroups() async throws {
        // Given: Field with multiple calculation groups
        let modelName = "Invoice_testParseMultipleCalculationGroups"
        let json: [String: Any] = [
            "total": [
                "calculationGroups": [
                    [
                        "id": "multiply",
                        "formula": "total = price * quantity",
                        "dependentFields": ["price", "quantity"],
                        "priority": 1
                    ],
                    [
                        "id": "add_tax",
                        "formula": "total = subtotal + tax",
                        "dependentFields": ["subtotal", "tax"],
                        "priority": 2
                    ]
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Both groups should be parsed
        let hints = result.fieldHints["total"]
        #expect(hints?.calculationGroups?.count == 2)
        #expect(hints?.calculationGroups?.first?.priority == 1)
        #expect(hints?.calculationGroups?.last?.priority == 2)
    }
    
    @Test func testParseCalculationGroupsMissing() async throws {
        // Given: Field without calculation groups
        let modelName = "User_testParseCalculationGroupsMissing"
        let json: [String: Any] = [
            "username": [
                "expectedLength": "20"
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Calculation groups should be nil
        let hints = result.fieldHints["username"]
        #expect(hints?.calculationGroups == nil)
    }
    
    // MARK: - Combined OCR and Calculation Groups Tests
    
    @Test func testParseOCRAndCalculationGroupsTogether() async throws {
        // Given: Field with both OCR hints and calculation groups
        let modelName = "FuelReceipt_testParseOCRAndCalculationGroupsTogether"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal", "fuel quantity"],
                "calculationGroups": [
                    [
                        "id": "from_price_total",
                        "formula": "gallons = total_price / price_per_gallon",
                        "dependentFields": ["total_price", "price_per_gallon"],
                        "priority": 1
                    ]
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName)
        
        // Then: Both should be parsed
        let hints = result.fieldHints["gallons"]
        #expect(hints?.ocrHints?.count == 3)
        #expect(hints?.calculationGroups?.count == 1)
        #expect(hints?.calculationGroups?.first?.formula == "gallons = total_price / price_per_gallon")
    }
    
    // MARK: - Apply Hints to DynamicFormField Tests
    
    @Test func testApplyOCRHintsToDynamicFormField() {
        // Given: Hints with OCR hints
        let hints = FieldDisplayHints(
            expectedLength: 10,
            ocrHints: ["gallons", "gal"]
        )
        
        // When: Creating field and applying hints
        var field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons"
        )
        field = field.applying(hints: hints)
        
        // Then: Field should have OCR hints for extraction; flags unchanged (Issue #404)
        #expect(field.ocrHints?.count == 2)
        #expect(field.ocrHints?.contains("gallons") == true)
        #expect(field.supportsOCR == false)
        #expect(field.displayOCR == false)
    }

    @Test func testParseSupportsOCRAndDisplayOCRFromHintsFile() async throws {
        let modelName = "FuelReceipt_testParseSupportsOCRAndDisplayOCR"
        let json: [String: Any] = [
            "station": [
                "ocrHints": ["station", "fuel stop"],
                "supportsOCR": true,
                "displayOCR": false
            ],
            "notes": [
                "ocrHints": ["notes"],
                "supportsOCR": false,
                "displayOCR": true
            ]
        ]
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let result = createTestLoader().loadHintsResult(for: uniqueModelName)
        let station = result.fieldHints["station"]
        #expect(station?.ocrHints == ["station", "fuel stop"])
        #expect(station?.supportsOCR == true)
        #expect(station?.displayOCR == false)

        let notes = result.fieldHints["notes"]
        #expect(notes?.supportsOCR == false)
        #expect(notes?.displayOCR == true)
    }

    @Test func testApplyHintsFileOCRFlagsWithoutInferringFromOCRHintsAlone() async throws {
        let modelName = "FuelReceipt_testApplyHintsFileOCRFlags"
        let json: [String: Any] = [
            "station": [
                "ocrHints": ["station"],
                "supportsOCR": true,
                "displayOCR": false
            ],
            "gallons": [
                "ocrHints": ["gallons", "gal"]
            ]
        ]
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let result = createTestLoader().loadHintsResult(for: uniqueModelName)

        let station = DynamicFormField(id: "station", contentType: .text, label: "Station")
            .applying(hints: result.fieldHints["station"]!)
        #expect(station.ocrHints == ["station"])
        #expect(station.supportsOCR == true)
        #expect(station.displayOCR == false)

        let gallons = DynamicFormField(id: "gallons", contentType: .number, label: "Gallons")
            .applying(hints: result.fieldHints["gallons"]!)
        #expect(gallons.ocrHints == ["gallons", "gal"])
        #expect(gallons.supportsOCR == false)
        #expect(gallons.displayOCR == false)
    }
    
    @Test func testApplyCalculationGroupsToDynamicFormField() {
        // Given: Hints with calculation groups
        let calculationGroup = CalculationGroup(
            id: "multiply",
            formula: "total = price * quantity",
            dependentFields: ["price", "quantity"],
            priority: 1
        )
        let hints = FieldDisplayHints(
            expectedLength: 10,
            calculationGroups: [calculationGroup]
        )
        
        // When: Creating field and applying hints
        var field = DynamicFormField(
            id: "total",
            contentType: .number,
            label: "Total"
        )
        field = field.applying(hints: hints)
        
        // Then: Groups merge; calculationGroups must not force isCalculated (Issue #404 follow-through)
        #expect(field.calculationGroups?.count == 1)
        #expect(field.calculationGroups?.first?.id == "multiply")
        #expect(field.isCalculated == false)
    }

    @Test func testApplyHintsCanSetIsCalculatedWhenPresent() {
        let calculationGroup = CalculationGroup(
            id: "multiply",
            formula: "total = price * quantity",
            dependentFields: ["price", "quantity"],
            priority: 1
        )
        let hints = FieldDisplayHints(
            calculationGroups: [calculationGroup],
            isCalculated: true
        )
        let field = DynamicFormField(
            id: "total",
            contentType: .number,
            label: "Total"
        ).applying(hints: hints)

        #expect(field.calculationGroups?.count == 1)
        #expect(field.isCalculated == true)
    }
    
    @Test func testApplyBothOCRAndCalculationGroupsToField() {
        // Given: Hints with both OCR and calculation groups
        let calculationGroup = CalculationGroup(
            id: "from_price_total",
            formula: "gallons = total_price / price_per_gallon",
            dependentFields: ["total_price", "price_per_gallon"],
            priority: 1
        )
        let hints = FieldDisplayHints(
            expectedLength: 10,
            ocrHints: ["gallons", "gal"],
            calculationGroups: [calculationGroup]
        )
        
        // When: Creating field and applying hints
        var field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons"
        )
        field = field.applying(hints: hints)
        
        // Then: Field should have both; ocrHints do not enable OCR flags (Issue #404)
        #expect(field.ocrHints?.count == 2)
        #expect(field.calculationGroups?.count == 1)
        #expect(field.supportsOCR == false)
        #expect(field.displayOCR == false)
        #expect(field.isCalculated == false)
    }
    
    // MARK: - Internationalization Tests
    
    @Test func testParseLanguageSpecificOCRHints() async throws {
        // Given: Hints file with language-specific OCR hints
        let modelName = "FuelReceipt_testParseLanguageSpecificOCRHints"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal"],  // Default/fallback
                "ocrHints.es": ["galones", "gal"],
                "ocrHints.fr": ["gallons", "litres"]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing with Spanish locale
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName, locale: Locale(identifier: "es"))
        
        // Then: Should use Spanish OCR hints
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 2)
        #expect(hints?.ocrHints?.contains("galones") == true)
        #expect(hints?.ocrHints?.contains("gal") == true)
    }
    
    @Test func testParseLanguageSpecificOCRHintsFallbackToDefault() async throws {
        // Given: Hints file with default OCR hints but no language-specific for current locale
        let modelName = "FuelReceipt_testParseLanguageSpecificOCRHintsFallbackToDefault"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal"],  // Default/fallback
                "ocrHints.es": ["galones", "gal"]  // Only Spanish, no French
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing with French locale (not in file)
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName, locale: Locale(identifier: "fr"))
        
        // Then: Should fallback to default OCR hints
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 2)
        #expect(hints?.ocrHints?.contains("gallons") == true)
        #expect(hints?.ocrHints?.contains("gal") == true)
    }
    
    @Test func testParseLanguageSpecificOCRHintsUsesCurrentLocale() async throws {
        // Given: Hints file with multiple language-specific OCR hints
        let modelName = "FuelReceipt_testParseLanguageSpecificOCRHintsUsesCurrentLocale"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal"],  // Default/fallback
                "ocrHints.en": ["gallons", "gal"],
                "ocrHints.es": ["galones", "gal"],
                "ocrHints.fr": ["gallons", "litres"]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing with English locale
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName, locale: Locale(identifier: "en"))
        
        // Then: Should use English OCR hints
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 2)
        #expect(hints?.ocrHints?.contains("gallons") == true)
        #expect(hints?.ocrHints?.contains("gal") == true)
    }
    
    @Test func testParseLanguageSpecificOCRHintsBackwardCompatible() async throws {
        // Given: Existing hints file with only default OCR hints (no language-specific)
        let modelName = "FuelReceipt_testParseLanguageSpecificOCRHintsBackwardCompatible"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal"]  // Only default, no language-specific
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing with any locale
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName, locale: Locale(identifier: "es"))
        
        // Then: Should use default OCR hints (backward compatible)
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 2)
        #expect(hints?.ocrHints?.contains("gallons") == true)
        #expect(hints?.ocrHints?.contains("gal") == true)
    }
    
    @Test func testParseLanguageSpecificOCRHintsWithCalculationGroups() async throws {
        // Given: Hints file with both language-specific OCR hints and calculation groups
        let modelName = "FuelReceipt_testParseLanguageSpecificOCRHintsWithCalculationGroups"
        let json: [String: Any] = [
            "gallons": [
                "expectedLength": "10",
                "ocrHints": ["gallons", "gal"],
                "ocrHints.es": ["galones", "gal"],
                "calculationGroups": [
                    [
                        "id": "from_price_total",
                        "formula": "gallons = total_price / price_per_gallon",
                        "dependentFields": ["total_price", "price_per_gallon"],
                        "priority": 1
                    ]
                ]
            ]
        ]
        
        let (testFile, uniqueModelName) = try writeHintsFile(modelName: modelName, json: json)
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        // When: Parsing with Spanish locale
        let loader = createTestLoader()
        let result = loader.loadHintsResult(for: uniqueModelName, locale: Locale(identifier: "es"))
        
        // Then: Should have both Spanish OCR hints and calculation groups
        let hints = result.fieldHints["gallons"]
        #expect(hints != nil)
        #expect(hints?.ocrHints?.count == 2)
        #expect(hints?.ocrHints?.contains("galones") == true)
        #expect(hints?.calculationGroups?.count == 1)
        #expect(hints?.calculationGroups?.first?.formula == "gallons = total_price / price_per_gallon")
    }
}

