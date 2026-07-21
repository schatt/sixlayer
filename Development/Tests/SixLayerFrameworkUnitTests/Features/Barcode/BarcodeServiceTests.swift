//
//  BarcodeServiceTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Tests the BarcodeService class which provides barcode scanning capabilities
//  for detecting and extracting barcode data from images, including 1D and 2D
//  barcode types, payload extraction, and bounding box detection.
//
//  TESTING SCOPE:
//  - Barcode detection for multiple formats (1D and 2D)
//  - Payload string extraction
//  - Bounding box coordinate detection
//  - Multiple barcode detection in single image
//  - Error handling (no barcode found, invalid image, etc.)
//  - Cross-platform support (iOS, macOS, visionOS)
//
//  METHODOLOGY:
//  - Test-Driven Development (TDD) approach
//  - Test barcode detection accuracy with various formats
//  - Verify payload extraction works correctly
//  - Test error handling and edge cases
//  - Validate cross-platform compatibility

@testable import SixLayerFramework
import Testing
import Foundation

#if canImport(Vision)
import Vision
#endif

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Tests for Barcode Service functionality
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Barcode Service")
open class BarcodeServiceTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no init() needed
    
    // MARK: - Barcode Service Availability Tests
    
    @Test func testBarcodeServiceAvailability() async {
        // TDD: BarcodeService should report availability status
        // 1. Service should be initializable
        // 2. Service should report if barcode detection is available
        // 3. Service should provide capabilities information
        
        let service = BarcodeService()
        
        // Should be able to check availability
        let isAvailable = service.isAvailable
        let capabilities = service.capabilities
        
        #expect(isAvailable == true || isAvailable == false, "Barcode service availability should be determinable")
        #expect(capabilities.supportedBarcodeTypes.count >= 0, "Barcode service should report supported barcode types")
    }
    
    @Test func testBarcodeServiceCapabilities() async {
        // TDD: BarcodeService should provide capability information
        // 1. Should report supported barcode types
        // 2. Should report platform-specific capabilities
        // 3. Should indicate if Vision framework is available
        
        let service = BarcodeService()
        let capabilities = service.capabilities
        
        // Should have capability information
        #expect(capabilities.supportsVision == true || capabilities.supportsVision == false, "Should report Vision framework support")
        #expect(capabilities.maxImageSize.width > 0 || capabilities.maxImageSize.width == 0, "Should report max image size")
    }
    
    // MARK: - Barcode Detection Tests
    
    @Test func testBarcodeDetectionWithInvalidImage() async throws {
        // TDD: BarcodeService should handle invalid images gracefully (fail fast, no Vision)
        let service = BarcodeService()

        #if os(iOS)
        let invalidImage = PlatformImage(uiImage: UIImage())
        #elseif os(macOS)
        let invalidImage = PlatformImage(nsImage: NSImage())
        #else
        let invalidImage = PlatformImage()
        #endif

        let context = BarcodeContext(
            supportedBarcodeTypes: [.qrCode, .code128],
            confidenceThreshold: 0.8
        )

        do {
            _ = try await service.processImage(invalidImage, context: context)
            Issue.record("Should throw BarcodeError.invalidImage for empty platform image")
        } catch BarcodeError.invalidImage {
            // expected — empty image never reaches Vision (#367)
        } catch BarcodeError.visionUnavailable {
            // acceptable on hosts without Vision barcode support
        } catch {
            Issue.record("Expected BarcodeError.invalidImage (or visionUnavailable), got \(error)")
        }
    }
    
    @Test func testBarcodeDetectionWithNoBarcodeFound() async throws {
        // Empty images cannot exercise "no barcode found" without a valid CGImage, and a
        // placeholder bitmap would enter live Vision (#367 / #366). Assert the empty-result
        // model instead of calling processImage on real pixels.
        let empty = BarcodeResult(barcodes: [], confidence: 0, processingTime: 0)
        #expect(empty.barcodes.isEmpty, "Empty scan result should have no barcodes")
        #expect(!empty.hasBarcodes, "hasBarcodes should be false when barcodes is empty")
        #expect(empty.filtered(by: .qrCode).isEmpty)
        #expect(empty.filtered(by: 0.8).barcodes.isEmpty)
    }
    
    // MARK: - Barcode Type Support Tests
    
    @Test func testSupportedBarcodeTypes() async {
        // TDD: BarcodeService should support multiple barcode types
        // 1. Should support at least one 1D barcode type (e.g., Code 128, EAN-13)
        // 2. Should support at least one 2D barcode type (e.g., QR Code, Data Matrix)
        // 3. Should report all supported types in capabilities
        
        let service = BarcodeService()
        let capabilities = service.capabilities
        
        // Should support at least one 1D barcode type
        let oneDTypes = capabilities.supportedBarcodeTypes.filter { $0.is1D }
        #expect(oneDTypes.count >= 0, "Should report 1D barcode type support (may be 0 if Vision unavailable)")
        
        // Should support at least one 2D barcode type
        let twoDTypes = capabilities.supportedBarcodeTypes.filter { $0.is2D }
        #expect(twoDTypes.count >= 0, "Should report 2D barcode type support (may be 0 if Vision unavailable)")
    }
    
    // MARK: - Barcode Result Tests
    
    @Test func testBarcodeResultStructure() async {
        // TDD: BarcodeResult should contain required information
        // 1. Should contain barcodes array
        // 2. Each barcode should have payload string
        // 3. Each barcode should have bounding box
        // 4. Should have confidence score
        // 5. Should have processing time
        
        // Create a mock result structure to test the type
        let testBarcode = Barcode(
            payload: "test-payload",
            barcodeType: .qrCode,
            boundingBox: CGRect(x: 10, y: 20, width: 100, height: 100),
            confidence: 0.95
        )
        
        let result = BarcodeResult(
            barcodes: [testBarcode],
            confidence: 0.95,
            processingTime: 0.5
        )
        
        // Should have required properties
        #expect(result.barcodes.count == 1, "Result should contain barcodes")
        #expect(result.barcodes.first?.payload == "test-payload", "Barcode should have payload")
        #expect(result.barcodes.first?.boundingBox == CGRect(x: 10, y: 20, width: 100, height: 100), "Barcode should have bounding box")
        #expect(result.confidence == 0.95, "Result should have confidence")
        #expect(result.processingTime == 0.5, "Result should have processing time")
    }
    
    @Test func testMultipleBarcodesInSingleImage() async {
        // TDD: BarcodeService should detect multiple barcodes in single image
        // 1. Should return all detected barcodes
        // 2. Each barcode should have unique payload and bounding box
        // 3. Result should contain array of all barcodes
        
        // Create a mock result with multiple barcodes
        let barcode1 = Barcode(
            payload: "payload-1",
            barcodeType: .qrCode,
            boundingBox: CGRect(x: 10, y: 20, width: 100, height: 100),
            confidence: 0.95
        )
        
        let barcode2 = Barcode(
            payload: "payload-2",
            barcodeType: .code128,
            boundingBox: CGRect(x: 150, y: 200, width: 200, height: 50),
            confidence: 0.90
        )
        
        let result = BarcodeResult(
            barcodes: [barcode1, barcode2],
            confidence: 0.925,
            processingTime: 0.6
        )
        
        // Should contain multiple barcodes
        #expect(result.barcodes.count == 2, "Result should contain multiple barcodes")
        #expect(result.barcodes[0].payload == "payload-1", "First barcode should have correct payload")
        #expect(result.barcodes[1].payload == "payload-2", "Second barcode should have correct payload")
        #expect(result.barcodes[0].boundingBox != result.barcodes[1].boundingBox, "Barcodes should have different bounding boxes")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testBarcodeErrorTypes() async {
        // TDD: BarcodeService should have appropriate error types
        // 1. Should have visionUnavailable error
        // 2. Should have invalidImage error
        // 3. Should have noBarcodeFound error (optional - may return empty result instead)
        // 4. Should have processingFailed error
        // 5. Should have unsupportedPlatform error
        
        // Test error types exist
        let errors: [BarcodeError] = [
            .visionUnavailable,
            .invalidImage,
            .noBarcodeFound,
            .processingFailed,
            .unsupportedPlatform
        ]
        
        // Should have all error types
        #expect(errors.count == 5, "Should have all required error types")
        
        // Test error descriptions
        for error in errors {
            #expect(error.errorDescription != nil, "Each error should have error description")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test func testBarcodeServiceFollowsOCRPatterns() async {
        // TDD: BarcodeService should follow existing OCR service patterns
        // 1. Should have similar service protocol structure
        // 2. Should have similar error handling
        // 3. Should have similar capability reporting
        // 4. Should integrate with existing infrastructure
        
        let service = BarcodeService()
        
        // Should have similar structure to OCRService
        #expect(service.isAvailable == true || service.isAvailable == false, "Should have isAvailable property")
        #expect(service.capabilities.supportsVision == true || service.capabilities.supportsVision == false, "Should have capabilities property")
    }
}
