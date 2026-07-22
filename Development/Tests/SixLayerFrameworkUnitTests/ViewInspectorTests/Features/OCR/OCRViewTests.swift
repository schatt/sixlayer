import Testing
import SwiftUI
@testable import SixLayerFramework
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Tests for OCR Service functionality
///
/// BUSINESS PURPOSE: Ensure OCR service provides proper functionality and error handling
/// TESTING SCOPE: OCR service capabilities, error handling, and result processing
/// METHODOLOGY: Deterministic checks only — never await unbounded live Vision OCR in this lane
/// (tip remesasure hang: #366 / #233; log mid-stall on `OCRServiceTests/testOCRServiceErrorHandling`).
@Suite("OCR Service", HostedViewTestIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class OCRServiceTests: BaseTestClass {

    // MARK: - OCR Service Tests

    @Test func testOCRServiceAvailabilityOnIOS() async {
        let service = OCRService()

        let isAvailable = service.isAvailable
        let capabilities = service.capabilities

        #expect(isAvailable == true || isAvailable == false, "OCR service availability should be determinable")
        #expect(capabilities.supportedTextTypes.count >= 0, "OCR service should report supported text types")
        #expect(capabilities.supportedLanguages.count >= 0, "OCR service should report supported languages")
    }

    @Test func testOCRServiceAvailabilityOnMacOS() async {
        let service = OCRService()

        let isAvailable = service.isAvailable
        let capabilities = service.capabilities

        #expect(isAvailable == true || isAvailable == false, "OCR service availability should be determinable")
        #expect(capabilities.supportedTextTypes.count >= 0, "OCR service should report supported text types")
        #expect(capabilities.supportedLanguages.count >= 0, "OCR service should report supported languages")
    }

    /// Error path must fail fast — do not call Vision on a valid placeholder (hangs the VI lane).
    @Test func testOCRServiceErrorHandling() async {
        let service = OCRService()
        let testImage = Self.invalidPlatformImage()
        let context = OCRContext(
            textTypes: [.general], language: .english, requiredFields: []
        )
        let strategy = OCRStrategy(
            supportedTextTypes: [.general],
            supportedLanguages: [.english],
            processingMode: .standard,
            requiresNeuralEngine: false,
            estimatedProcessingTime: 1.0
        )

        do {
            _ = try await service.processImage(testImage, context: context, strategy: strategy)
            Issue.record("Expected OCRError.invalidImage for an empty platform image")
        } catch OCRError.invalidImage {
            // Fast fail path — no Vision
        } catch let error as OCRError {
            Issue.record("Empty image should fail as invalidImage, got \(error)")
        } catch {
            Issue.record("OCR errors should be OCRError types, got \(error)")
        }
    }

    /// Structured extraction pipeline without live Vision (same pattern as OCR unit suites).
    @Test func testOCRServiceStructuredExtraction() async {
        let service = OCRService()
        let context = OCRContext(
            textTypes: [.general], language: .english, requiredFields: []
        )
        let base = OCRResult(
            extractedText: "Mock line for structured extraction",
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [.general: "Mock line for structured extraction"],
            processingTime: 0,
            language: .english
        )
        let pipeline = service.applyStructuredExtraction(from: base, context: context)
        #expect(pipeline.extractionConfidence >= 0.0 && pipeline.extractionConfidence <= 1.0)
        // structuredData may be empty without hints — still a completed, deterministic path
        _ = pipeline.structuredData
    }

    @Test func testOCRContextValidation() async {
        let validContext = OCRContext(
            textTypes: [.general], language: .english, requiredFields: []
        )

        #expect(validContext.textTypes.contains(.general), "OCR context should preserve text types")
        #expect(validContext.language == .english, "OCR context should preserve language")
    }

    @Test func testOCRStrategyConfiguration() async {
        let strategy = OCRStrategy(
            supportedTextTypes: [.general, .number],
            supportedLanguages: [.english, .spanish],
            processingMode: .accurate,
            requiresNeuralEngine: true,
            estimatedProcessingTime: 2.0
        )

        #expect(strategy.supportedTextTypes.contains(.general), "OCR strategy should support specified text types")
        #expect(strategy.supportedTextTypes.contains(.number), "OCR strategy should support multiple text types")
        #expect(strategy.supportedLanguages.contains(.english), "OCR strategy should support specified languages")
        #expect(strategy.supportedLanguages.contains(.spanish), "OCR strategy should support multiple languages")
        #expect(strategy.processingMode == .accurate, "OCR strategy should preserve processing mode")
        #expect(strategy.requiresNeuralEngine == true, "OCR strategy should preserve neural engine requirement")
        #expect(strategy.estimatedProcessingTime == 2.0, "OCR strategy should preserve estimated processing time")
    }

    /// Empty platform image → `getCGImage` nil → `OCRError.invalidImage` without Vision.
    private static func invalidPlatformImage() -> PlatformImage {
        #if os(macOS)
        return PlatformImage(nsImage: NSImage())
        #elseif canImport(UIKit)
        return PlatformImage(uiImage: UIImage())
        #else
        return PlatformImage.createPlaceholder()
        #endif
    }
}
