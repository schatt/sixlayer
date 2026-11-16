//
//  OCRFieldAverageDeviationThreshold679Tests.swift
//  SixLayerFrameworkTests
//
//  #679: fieldAverages magnitude is passed in; how far from that average is
//  "unusual" must be configurable (today hardcoded at 50%).
//

@testable import SixLayerFramework
import Testing
import Foundation

@Suite("OCR field average deviation threshold (#679)")
struct OCRFieldAverageDeviationThreshold679Tests {

    /// Average 4.34, value 9.99 → ~130% deviation (classic docs example).
    private let farFromAverage = "9.99"
    private let typicalAverage = 4.34
    private let wideRange = ValueRange(min: 2.0, max: 10.0)

    @Test func contextStoresFieldAverageMaxPercentDeviation() {
        let context = OCRContext(
            fieldAverages: ["pricePerGallon": typicalAverage],
            fieldAverageMaxPercentDeviation: 25
        )
        #expect(context.fieldAverageMaxPercentDeviation == 25)
        #expect(context.fieldAverages?["pricePerGallon"] == typicalAverage)
    }

    @Test func nilDeviationMeansUseDefaultFiftyPercent() {
        let context = OCRContext(fieldAverages: ["pricePerGallon": typicalAverage])
        #expect(context.fieldAverageMaxPercentDeviation == nil)
        #expect(OCRContext.defaultFieldAverageMaxPercentDeviation == 50)
    }

    @Test func withCaptureRegionPreservesDeviationThreshold() {
        let context = OCRContext(
            fieldAverages: ["pricePerGallon": typicalAverage],
            fieldAverageMaxPercentDeviation: 12.5
        ).with(captureRegionCode: "US")
        #expect(context.fieldAverageMaxPercentDeviation == 12.5)
        #expect(context.captureRegionCode == "US")
    }

    @Test func defaultThresholdFlagsValueFarFromAverage() {
        let pipeline = runValidation(
            value: farFromAverage,
            average: typicalAverage,
            maxPercentDeviation: nil
        )
        #expect(
            pipeline.adjustedFields["pricePerGallon"]?.contains("significantly different from typical") == true,
            "nil threshold must keep the legacy 50% gate; ~130% deviation should flag"
        )
    }

    @Test func raisedThresholdDoesNotFlagSameDeviation() {
        let pipeline = runValidation(
            value: farFromAverage,
            average: typicalAverage,
            maxPercentDeviation: 200
        )
        #expect(
            pipeline.adjustedFields["pricePerGallon"]?.contains("significantly different from typical") != true,
            "200% gate should not flag ~130% deviation"
        )
    }

    @Test func tightenedThresholdFlagsModestDeviation() {
        // ~15% from 4.34
        let pipeline = runValidation(
            value: "5.00",
            average: typicalAverage,
            maxPercentDeviation: 10
        )
        #expect(
            pipeline.adjustedFields["pricePerGallon"]?.contains("significantly different from typical") == true,
            "10% gate should flag ~15% deviation"
        )
    }

    @Test func tightenedThresholdDoesNotFlagWhenWithinGate() {
        let pipeline = runValidation(
            value: "5.00",
            average: typicalAverage,
            maxPercentDeviation: 50
        )
        #expect(
            pipeline.adjustedFields["pricePerGallon"]?.contains("significantly different from typical") != true,
            "50% gate should not flag ~15% deviation"
        )
    }

    private func runValidation(
        value: String,
        average: Double,
        maxPercentDeviation: Double?
    ) -> (
        structuredData: [String: String],
        adjustedFields: [String: String],
        extractionConfidence: Float,
        missingRequiredFields: [String]
    ) {
        let service = OCRService()
        let base = OCRResult(
            extractedText: "PPG \(value)",
            confidence: 1.0
        )
        let context = OCRContext(
            textTypes: [.number],
            language: .english,
            extractionHints: ["pricePerGallon": #"PPG\s+(\d+\.\d+)"#],
            extractionMode: .custom,
            fieldRanges: ["pricePerGallon": wideRange],
            fieldAverages: ["pricePerGallon": average],
            fieldAverageMaxPercentDeviation: maxPercentDeviation
        )
        return service.applyStructuredExtraction(from: base, context: context)
    }
}
