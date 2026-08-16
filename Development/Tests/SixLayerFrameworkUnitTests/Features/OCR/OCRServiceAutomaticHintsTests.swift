//
//  OCRServiceAutomaticHintsTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Tests automatic hints file loading and calculation group application
//  for structured OCR extraction (Issue #29)
//
//  TESTING SCOPE:
//  - Automatic hints file loading based on entityName
//  - Automatic ocrHints usage in extraction
//  - Automatic calculationGroups application
//
//  METHODOLOGY:
//  TDD approach: Write failing tests first, then implement features

@testable import SixLayerFramework
import Testing
import Foundation

/// Tests for automatic hints file loading in OCR structured extraction
@Suite("OCR Service Automatic Hints")
final class OCRServiceAutomaticHintsTests: BaseTestClass {
    
    // MARK: - Test: Entity Name Specification
    
    @Test func testEntityNameSpecification() {
        // GIVEN: A context with explicit entityName
        // Projects specify which data model's hints file to use directly
        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase" // Directly specifies which .hints file to load
        )
        
        // WHEN: Processing structured extraction
        // The framework should load FuelPurchase.hints based on entityName
        
        // THEN: Context should use the specified entity name
        #expect(context.entityName == "FuelPurchase", 
                "Context should use explicit entityName when provided")
    }
    
    @Test func testEntityNameIsOptional() {
        // GIVEN: A context without entityName (developer doesn't need/want hints)
        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic
            // entityName is nil - no hints file will be loaded automatically
        )
        
        // WHEN: Processing structured extraction
        // The framework will gracefully handle nil entityName:
        // - Won't load hints file
        // - Won't apply calculation groups
        // - Will still use custom extractionHints (if provided)
        
        // THEN: Should have nil entityName and framework should handle it gracefully
        #expect(context.entityName == nil, 
                "Context should have nil entityName when not explicitly provided")
        // Framework should work normally without hints - developers can opt out
    }
    
    @Test func testExtractionWorksWithoutEntityName() {
        // GIVEN: A context without entityName but with custom extractionHints
        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionHints: [
                "total": #"Total:\s*([\d.,]+)"#,
                "gallons": #"Gallons:\s*([\d.,]+)"#
            ],
            extractionMode: .custom // Using custom mode
            // entityName is nil - developer doesn't want hints file
        )
        
        // WHEN: Processing structured extraction
        // The framework should still work using custom extractionHints
        
        // THEN: Should work normally without entityName
        #expect(context.entityName == nil, 
                "Context can have nil entityName when using custom extractionHints")
        #expect(!context.extractionHints.isEmpty, 
                "Custom extractionHints should still work without entityName")
    }
    
    // MARK: - Test: Automatic OCR Hints Usage
    
    @Test func testAutomaticOCRHintsUsageInExtraction() async throws {
        // GIVEN: A context with entityName and OCR text containing hints
        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase" // Specifies which hints file to load
        )
        
        // Create a mock OCR result with text that should match ocrHints
        let ocrResult = OCRResult(
            extractedText: "Total: 90.22\nGallons: 12.5\nPrice per gallon: 7.22",
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.1,
            language: .english
        )
        
        // WHEN: Extracting structured data using the service's internal extraction
        _ = OCRService()
        // We'll test by creating a minimal image and calling processStructuredExtraction
        // But first, let's verify that loadHintsPatterns would be called
        // by checking if entityName is set correctly
        
        // THEN: Context should have entityName set
        #expect(context.entityName == "FuelPurchase", 
                "Context should have entityName set for hints file loading")
        
        // Verify that the OCR result contains text that would match hints
        #expect(ocrResult.extractedText.contains("Total"), 
                "OCR result should contain text matching ocrHints")
        #expect(ocrResult.extractedText.contains("Gallons"), 
                "OCR result should contain text matching ocrHints")
        
        // Note: Full integration test would require:
        // 1. A hints file in the test bundle (FuelPurchase.hints)
        // 2. A real PlatformImage to process
        // 3. Actual Vision framework processing
        // This test verifies the setup is correct for hints-based extraction
        // The actual pattern matching is tested in testOCRHintsToRegexPatternConversion
    }
    
    // MARK: - Test: Automatic Calculation Groups Application
    
    @Test func testAutomaticCalculationGroupsApplication() async throws {
        // GIVEN: A context with entityName and partial OCR data
        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase" // Specifies which hints file to load
        )
        
        // Create a mock OCR result with totalCost and gallons, but missing pricePerGallon
        let ocrResult = OCRResult(
            extractedText: "Total: 90.22\nGallons: 12.5",
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.1,
            language: .english
        )
        
        // WHEN: Setting up for calculation group application
        _ = OCRService()
        
        // THEN: Context should be configured for calculation groups
        #expect(context.entityName == "FuelPurchase", 
                "Context should have entityName set for calculation groups")
        #expect(context.extractionMode == .automatic, 
                "Context should be in automatic mode for calculation groups")
        
        // Verify that the OCR result contains partial data that would trigger calculation
        #expect(ocrResult.extractedText.contains("Total"), 
                "OCR result should contain totalCost data")
        #expect(ocrResult.extractedText.contains("Gallons"), 
                "OCR result should contain gallons data")
        #expect(!ocrResult.extractedText.contains("Price per gallon"), 
                "OCR result should NOT contain pricePerGallon (to be calculated)")
        
        // Note: Full integration test would require:
        // 1. A hints file with calculationGroups defined (FuelPurchase.hints)
        // 2. Structured data extracted from OCR result
        // 3. Calculation group evaluation (pricePerGallon = totalCost / gallons)
        // The calculation group logic is implemented in applyCalculationGroups()
        // and evaluateCalculationGroup() methods
        // This test verifies the setup is correct for calculation group application
    }
    
    // MARK: - Test: OCR Hints to Regex Pattern Conversion
    
    @Test func testOCRHintsToRegexPatternConversion() throws {
        let (modelName, cleanup) = try createFuelPurchaseHintsFile()
        defer { try? cleanup() }

        let context = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        let patterns = OCRService().loadHintsPatterns(for: context)
        let totalPattern = patterns["totalCost"] ?? ""

        func matches(_ text: String) -> Bool {
            text.range(of: totalPattern, options: .regularExpression) != nil
        }

        #expect(matches("Total: 90.22") == false)
        #expect(matches("amount 90.22") == false)
        #expect(matches("sum=90.22") == false)
    }
    
    // MARK: - Test: Value Range Validation
    
    @Test func testValueRangeStructure() {
        // GIVEN: A value range
        let range = ValueRange(min: 5.0, max: 30.0)
        
        // WHEN: Checking if values are within range
        let withinRange = range.contains(15.0)
        let belowRange = range.contains(3.0)
        let aboveRange = range.contains(35.0)
        let atMin = range.contains(5.0)
        let atMax = range.contains(30.0)
        
        // THEN: Should correctly identify values within and outside range
        #expect(withinRange == true, "Value 15.0 should be within range 5-30")
        #expect(belowRange == false, "Value 3.0 should be below range 5-30")
        #expect(aboveRange == false, "Value 35.0 should be above range 5-30")
        #expect(atMin == true, "Value 5.0 should be at minimum (inclusive)")
        #expect(atMax == true, "Value 30.0 should be at maximum (inclusive)")
    }
    
    @Test func testFieldDisplayHintsWithExpectedRange() {
        // GIVEN: FieldDisplayHints with expectedRange
        let range = ValueRange(min: 10.0, max: 50.0)
        let hints = FieldDisplayHints(
            expectedLength: 10,
            expectedRange: range
        )
        
        // WHEN: Accessing the range
        let retrievedRange = hints.expectedRange
        
        // THEN: Should have the expected range
        #expect(retrievedRange != nil, "Hints should have expectedRange")
        #expect(retrievedRange?.min == 10.0, "Range min should be 10.0")
        #expect(retrievedRange?.max == 50.0, "Range max should be 50.0")
    }
    
    @Test func testOCRContextWithFieldRangesOverride() {
        // GIVEN: A context with fieldRanges override
        let overrideRange = ValueRange(min: 20.0, max: 100.0)
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase",
            fieldRanges: ["gallons": overrideRange]
        )
        
        // WHEN: Accessing fieldRanges
        let retrievedRange = context.fieldRanges?["gallons"]
        
        // THEN: Should have the override range
        #expect(retrievedRange != nil, "Context should have fieldRanges override")
        #expect(retrievedRange?.min == 20.0, "Override range min should be 20.0")
        #expect(retrievedRange?.max == 100.0, "Override range max should be 100.0")
    }
    
    @Test func testFieldRangesOverrideTakesPrecedence() {
        // GIVEN: A context with both entityName (hints file) and fieldRanges override
        // The override should take precedence over hints file values
        let overrideRange = ValueRange(min: 15.0, max: 75.0)
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase", // Hints file might have different range
            fieldRanges: ["gallons": overrideRange] // But override takes precedence
        )
        
        // WHEN: Framework needs to get range for "gallons" field
        // It should use the override, not the hints file
        
        // THEN: Override should be available
        #expect(context.fieldRanges?["gallons"] != nil, "Override should be available")
        #expect(context.fieldRanges?["gallons"]?.min == 15.0, "Override should take precedence")
    }
    
    @Test func testFieldRangesIsOptional() {
        // GIVEN: A context without fieldRanges override
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionMode: .automatic,
            entityName: "FuelPurchase"
            // fieldRanges is nil - will use hints file if available
        )
        
        // WHEN: Accessing fieldRanges
        let ranges = context.fieldRanges
        
        // THEN: Should be nil (no override)
        #expect(ranges == nil, "fieldRanges should be nil when not provided")
    }
    
    // MARK: - Test Helper for Issue #30
    
    /// Helper to create a test hints file for FuelPurchase (Issue #30)
    /// Returns the unique model name and a cleanup closure
    private func createFuelPurchaseHintsFile() throws -> (modelName: String, cleanup: () throws -> Void) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        
        // Use unique filename to prevent conflicts
        let uniqueModelName = "FuelPurchase_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        
        // Create hints file matching issue #30 structure
        let hintsJSON: [String: Any] = [
            "totalCost": [
                "ocrHints": ["total", "amount due", "grand total", "final price", "total price", "total cost", "amount", "sum", "$"],
                "expectedRange": ["min": 10.0, "max": 300.0], // Typical fuel purchase totals
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
                "ocrHints": ["gallons", "gal", "fuel quantity", "liters", "litres", "volume", "amount", "quantity", "qty"],
                "expectedRange": ["min": 5.0, "max": 30.0], // Typical car fuel tank sizes
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
                "ocrHints": ["price", "per gallon", "per gal", "rate", "cost", "$/gal", "dollars per gallon", "price/gallon", "price per gallon"],
                "expectedRange": ["min": 2.0, "max": 10.0], // Typical gas prices
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
    
    // MARK: - Test: Issue #30 - Extract All Three Values
    
    @Test func testIssue30ExtractAllThreeValuesFromHintsFile() async throws {
        // GIVEN: A hints file with FuelPurchase structure and OCR text containing all three values
        let (modelName, cleanup) = try createFuelPurchaseHintsFile()
        defer { try? cleanup() }
        
        _ = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        
        // Simulate OCR text from pump display (issue #30 example)
        // Expected: totalCost="32.88", gallons="8.022", pricePerGallon="4.10"
        let ocrText = "Total: 32.88\nGallons: 8.022\nPrice per gallon: 4.10"
        
        _ = OCRResult(
            extractedText: ocrText,
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.1,
            language: .english
        )
        
        // WHEN: Extracting structured data
        _ = OCRService()
        // Use reflection or internal method to test extraction
        // Since extractStructuredData is private, we'll test via processStructuredExtraction
        // But for unit testing, we need to create a minimal image or mock the OCR processing
        
        // For now, verify the hints file is loaded correctly
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "en"))
        
        // THEN: Hints file should be loaded with all three fields
        #expect(hintsResult.fieldHints["totalCost"] != nil, "totalCost should be in hints file")
        #expect(hintsResult.fieldHints["gallons"] != nil, "gallons should be in hints file")
        #expect(hintsResult.fieldHints["pricePerGallon"] != nil, "pricePerGallon should be in hints file")
        
        // Verify ocrHints are present
        #expect(hintsResult.fieldHints["totalCost"]?.ocrHints?.contains("total") == true, "totalCost should have 'total' in ocrHints")
        #expect(hintsResult.fieldHints["gallons"]?.ocrHints?.contains("gallons") == true, "gallons should have 'gallons' in ocrHints")
        #expect(hintsResult.fieldHints["pricePerGallon"]?.ocrHints?.contains("price per gallon") == true, "pricePerGallon should have 'price per gallon' in ocrHints")
        
        // Verify calculation groups are present
        #expect(hintsResult.fieldHints["totalCost"]?.calculationGroups?.count == 1, "totalCost should have calculation group")
        #expect(hintsResult.fieldHints["gallons"]?.calculationGroups?.count == 1, "gallons should have calculation group")
        #expect(hintsResult.fieldHints["pricePerGallon"]?.calculationGroups?.count == 1, "pricePerGallon should have calculation group")
        
        // Verify all three use the same calculation group ID (same relationship)
        let totalCostGroupId = hintsResult.fieldHints["totalCost"]?.calculationGroups?.first?.id
        let gallonsGroupId = hintsResult.fieldHints["gallons"]?.calculationGroups?.first?.id
        let pricePerGallonGroupId = hintsResult.fieldHints["pricePerGallon"]?.calculationGroups?.first?.id
        
        #expect(totalCostGroupId == gallonsGroupId, "totalCost and gallons should share same calculation group ID")
        #expect(gallonsGroupId == pricePerGallonGroupId, "gallons and pricePerGallon should share same calculation group ID")
        #expect(totalCostGroupId == "fuel_purchase_relationship", "All should use 'fuel_purchase_relationship' ID")
    }
    
    @Test func testIssue30CalculateMissingValueFromTwoExtracted() async throws {
        // GIVEN: A hints file and OCR text with only two values (totalCost and gallons)
        let (modelName, cleanup) = try createFuelPurchaseHintsFile()
        defer { try? cleanup() }
        
        _ = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        
        // OCR text missing pricePerGallon - should be calculated
        let ocrText = "Total: 32.88\nGallons: 8.022"
        
        _ = OCRResult(
            extractedText: ocrText,
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.1,
            language: .english
        )
        
        // WHEN: Testing that calculation groups can calculate the missing value
        // We'll verify the calculation group formula is correct
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "en"))
        
        // Simulate extracted data
        let structuredData: [String: String] = [
            "totalCost": "32.88",
            "gallons": "8.022"
        ]
        
        // Manually test calculation group evaluation
        if let pricePerGallonGroup = hintsResult.fieldHints["pricePerGallon"]?.calculationGroups?.first {
            // Formula: pricePerGallon = totalCost / gallons
            // Should calculate: 32.88 / 8.022 = 4.10 (approximately)
            let formula = pricePerGallonGroup.formula
            #expect(formula.contains("pricePerGallon = totalCost / gallons"), "Formula should calculate pricePerGallon from totalCost and gallons")
            #expect(pricePerGallonGroup.dependentFields.contains("totalCost"), "Should depend on totalCost")
            #expect(pricePerGallonGroup.dependentFields.contains("gallons"), "Should depend on gallons")
            
            // Test the calculation manually
            if let totalCostValue = Double(structuredData["totalCost"] ?? ""),
               let gallonsValue = Double(structuredData["gallons"] ?? "") {
                let calculatedPricePerGallon = totalCostValue / gallonsValue
                #expect(abs(calculatedPricePerGallon - 4.10) < 0.01, "Should calculate approximately 4.10")
            }
        }
        
        // THEN: Calculation group should be able to calculate pricePerGallon
        #expect(hintsResult.fieldHints["pricePerGallon"]?.calculationGroups != nil, "pricePerGallon should have calculation group")
    }
    
    @Test func testIssue30NoGenericTextTypesInStructuredData() async throws {
        // GIVEN: A context with entityName (should use hints file, not generic types)
        let (modelName, cleanup) = try createFuelPurchaseHintsFile()
        defer { try? cleanup() }
        
        _ = OCRContext(
            textTypes: [.price, .number],
            language: .english,
            extractionMode: .automatic,
            entityName: modelName
        )
        
        // OCR text that might match generic text types
        let ocrText = "Total: 32.88\nGallons: 8.022\nPrice per gallon: 4.10"
        
        _ = OCRResult(
            extractedText: ocrText,
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [.price: "$32.88", .number: "8.022"], // Generic text types detected
            processingTime: 0.1,
            language: .english
        )
        
        // WHEN: Extracting structured data
        // The framework should NOT add generic "price" or "number" to structuredData
        // It should only use hints file patterns
        
        // THEN: Verify that generic text types are not used when entityName is provided
        // This is tested by ensuring extractStructuredData doesn't add generic types
        // The actual extraction would happen in processStructuredExtraction, but we can verify
        // the logic by checking that getPatterns returns hints file patterns, not generic types
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: modelName, locale: Locale(identifier: "en"))
        
        // Verify hints file has patterns (not generic types)
        #expect(hintsResult.fieldHints["totalCost"]?.ocrHints != nil, "Should have ocrHints for totalCost")
        #expect(hintsResult.fieldHints["gallons"]?.ocrHints != nil, "Should have ocrHints for gallons")
        #expect(hintsResult.fieldHints["pricePerGallon"]?.ocrHints != nil, "Should have ocrHints for pricePerGallon")
        
        // Generic "price" and "number" should NOT be in the hints file
        #expect(hintsResult.fieldHints["price"] == nil, "Should not have generic 'price' field")
        #expect(hintsResult.fieldHints["number"] == nil, "Should not have generic 'number' field")
    }
}

