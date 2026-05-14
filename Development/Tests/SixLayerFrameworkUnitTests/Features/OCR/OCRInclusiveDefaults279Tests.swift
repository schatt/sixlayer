//
//  OCRInclusiveDefaults279Tests.swift
//  SixLayerFrameworkUnitTests
//
//  Validates inclusive OCR defaults and uncategorized extraction helpers (GitHub #279).
//

import Testing
@testable import SixLayerFramework

@Suite("OCR inclusive defaults (#279)")
struct OCRInclusiveDefaults279Tests {
    
    @Test func defaultOCRContextUsesInclusiveConfidence() {
        let context = OCRContext()
        #expect(context.confidenceThreshold == 0.35)
        #expect(context.strictVisionTextTypeFiltering == false)
    }
    
    @Test func visionStrategySupportedTextTypes_emptyWhenInclusive() {
        let context = OCRContext(
            textTypes: [.quantity, .price],
            strictVisionTextTypeFiltering: false
        )
        #expect(context.visionStrategySupportedTextTypes.isEmpty)
    }
    
    @Test func visionStrategySupportedTextTypes_passesThroughWhenStrict() {
        let context = OCRContext(
            textTypes: [.quantity, .price],
            strictVisionTextTypeFiltering: true
        )
        #expect(context.visionStrategySupportedTextTypes == [.quantity, .price])
    }
    
    @Test func ocrTextTypeInference_classifiesNumberAndPrice() {
        #expect(OCRTextTypeInference.inferredType(for: "12.34") == .number)
        #expect(OCRTextTypeInference.inferredType(for: "$3.49") == .price)
        #expect(OCRTextTypeInference.inferredType(for: "01/15/2026") == .date)
    }
    
    @Test func uncategorizedBuilder_skipsStructuredValuesAndLabels() {
        let lines = ["10.5", "20.0", "Shell"]
        let structured: Set<String> = ["10.5"]
        let extras = OCRUncategorizedExtractionBuilder.build(
            recognizedLines: lines,
            structuredValues: structured
        )
        #expect(extras.count == 1)
        #expect(extras[0].value == "20.0")
        #expect(extras[0].inferredTextType == .number)
        #expect(extras[0].label == "number[1]")
    }
}
