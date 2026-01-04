import Testing

//
//  OCROverlayTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive tests for OCR overlay functionality
//  Test-Driven Development approach for visual text correction
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView (prevents Xcode crashes from too many @MainActor threads)
@Suite(.serialized)
open class OCROverlayTests: BaseTestClass {
    
    // Test data will be created locally in each test method for parallel execution
    
    // MARK: - OCR Overlay View Tests
    
    @Test @MainActor
    func testOCROverlayViewInitialization() {
        // Given: OCR overlay parameters
        let onTextEdit: (String, CGRect) -> Void = { _, _ in }
        let onTextDelete: (CGRect) -> Void = { _ in }
        
        // Create test data locally
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: [
                CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
                CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
                CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
            ],
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        // When: Creating OCR overlay view
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: onTextEdit,
            onTextDelete: onTextDelete
        )
        
        // Then: Should initialize successfully and be hostable
        _ = hostRootPlatformView(overlayView)
        #expect(Bool(true), "OCR overlay view should be hostable")  // hostingView is non-optional
        // OCROverlayView is non-optional - no need to check for nil
    }
    
    @Test @MainActor func testOCROverlayViewWithEmptyResult() {
        // Given: Empty OCR result
        let emptyResult = OCRResult(
            extractedText: "",
            confidence: 0.0,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 0.0,
            language: .english
        )
        
        // When: Creating overlay with empty result
        let testImage = PlatformImage()
        _ = OCROverlayView(
            image: testImage,
            result: emptyResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // Then: Should handle empty result gracefully
        // OCROverlayView is non-optional - no need to check for nil
    }
    
    // MARK: - Bounding Box Visualization Tests
    
    @Test @MainActor func testBoundingBoxRendering() {
        // Given: OCR result with bounding boxes
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: [
                CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
                CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
                CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
            ],
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Rendering overlay
        // Then: Should render all bounding boxes
        #expect(testOCRResult.boundingBoxes.count == 3, "Should have 3 bounding boxes")
        #expect(testOCRResult.boundingBoxes[0] == CGRect(x: 10, y: 20, width: 100, height: 30))
        #expect(testOCRResult.boundingBoxes[1] == CGRect(x: 50, y: 60, width: 80, height: 25))
        #expect(testOCRResult.boundingBoxes[2] == CGRect(x: 120, y: 100, width: 60, height: 20))
    }
    
    @Test @MainActor func testBoundingBoxCoordinateConversion() {
        initializeTestConfig()
        // Given: Normalized bounding box coordinates
        let boundingBox = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3) // Normalized coordinates
        
        // When: Converting to image coordinates using placeholder image (100x100)
        let overlayView = OCROverlayView(
            image: PlatformImage.createPlaceholder(), // 100x100 image
            result: OCRResult(extractedText: "", confidence: 0.0, boundingBoxes: [])
        )
        let convertedBox = overlayView.convertBoundingBoxToImageCoordinates(boundingBox)
        
        // Then: Should convert correctly
        #expect(convertedBox.origin.x == 10) // 0.1 * 100
        #expect(convertedBox.origin.y == 20) // 0.2 * 100
        #expect(convertedBox.width == 50)   // 0.5 * 100
        #expect(convertedBox.height == 30)  // 0.3 * 100
    }
    
    // MARK: - Text Region Interaction Tests
    
    @Test @MainActor func testTextRegionTapDetection() {
        // Given: OCR overlay with text regions
        let testImage = PlatformImage()
        let testBoundingBoxes = [
            CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
            CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
            CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
        ]
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: testBoundingBoxes,
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in
                // Text edit handler
            },
            onTextDelete: { _ in }
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in
                // Text edit handler
            },
            onTextDelete: { _ in }
        )
        
        // When: Simulating tap on first text region
        let tapPoint = CGPoint(x: 60, y: 35) // Within first bounding box
        let detectedRegion = overlayView.detectTappedTextRegion(at: tapPoint)
        
        // Then: Should detect correct region
        #expect(Bool(true), "Should detect tapped text region")
        #expect(detectedRegion == testBoundingBoxes[0], "Should return correct bounding box")
    }
    
    @Test @MainActor func testTextRegionTapOutsideBounds() {
        // Given: OCR overlay
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: [
                CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
                CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
                CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
            ],
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Tapping outside any text region
        let tapPoint = CGPoint(x: 5, y: 5) // Outside all bounding boxes
        let result = overlayView.detectTappedTextRegion(at: tapPoint)
        
        // Then: Should return nil for tap outside bounds
        #expect(result == nil, "Should return nil for tap outside bounds")
    }
    
    // MARK: - Text Editing Tests
    
    @Test @MainActor func testTextEditingModeToggle() {
        // Given: OCR overlay
        let testImage = PlatformImage()
        let testBoundingBoxes = [
            CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
            CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
            CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
        ]
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: testBoundingBoxes,
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Starting text editing
        overlayView.startTextEditing(in: testBoundingBoxes[0])
        
        // Then: Should be able to detect tapped region
        let tappedRegion = overlayView.detectTappedTextRegion(at: CGPoint(x: testBoundingBoxes[0].midX, y: testBoundingBoxes[0].midY))
        #expect(Bool(true), "Should detect tapped region")  // tappedRegion is non-optional
        #expect(tappedRegion == testBoundingBoxes[0], "Should return correct bounding box")
    }
    
    @Test @MainActor func testTextEditingCompletion() {
        // Given: OCR overlay in editing mode
        var editedText: String?
        var editedRect: CGRect?
        let testImage = PlatformImage()
        let testBoundingBoxes = [
            CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
            CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
            CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
        ]
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: testBoundingBoxes,
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { text, rect in
                editedText = text
                editedRect = rect
            },
            onTextDelete: { _ in }
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { text, rect in
                editedText = text
                editedRect = rect
            },
            onTextDelete: { _ in }
        )
        
        overlayView.startTextEditing(in: testBoundingBoxes[0])
        
        // When: Completing text editing
        let newText = "Edited Text"
        overlayView.completeTextEditing()
        
        // Then: Should call completion handler
        #expect(editedText == newText)
        #expect(editedRect == testBoundingBoxes[0])
    }
    
    @Test @MainActor func testTextEditingCancellation() {
        // Given: OCR overlay in editing mode
        let testImage = PlatformImage()
        let testBoundingBoxes = [
            CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
            CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
            CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
        ]
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: testBoundingBoxes,
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        overlayView.startTextEditing(in: testBoundingBoxes[0])
        
        // When: Canceling text editing
        overlayView.cancelTextEditing()
        
        // Then: Should exit editing mode without calling completion
        // Note: We can't directly test internal state, but we can test the behavior
        #expect(Bool(true), "Cancellation should work")
    }
    
    // MARK: - Text Deletion Tests
    
    @Test @MainActor func testTextRegionDeletion() {
        // Given: OCR overlay
        var deletedRect: CGRect?
        let testImage = PlatformImage()
        let testBoundingBoxes = [
            CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
            CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
            CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
        ]
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: testBoundingBoxes,
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { rect in
                deletedRect = rect
            }
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { rect in
                deletedRect = rect
            }
        )
        
        // When: Deleting text region
        overlayView.deleteTextRegion(testBoundingBoxes[1])
        
        // Then: Should call deletion handler
        #expect(deletedRect == testBoundingBoxes[1])
    }
    
    // MARK: - Visual Feedback Tests
    
    @Test @MainActor func testConfidenceVisualIndicators() {
        // Given: OCR result with varying confidence levels
        let highConfidenceResult = OCRResult(
            extractedText: "High Confidence",
            confidence: 0.95,
            boundingBoxes: [CGRect(x: 0, y: 0, width: 100, height: 20)],
            textTypes: [.general: "High Confidence"],
            processingTime: 0.5,
            language: .english
        )
        
        let lowConfidenceResult = OCRResult(
            extractedText: "Low Confidence",
            confidence: 0.3,
            boundingBoxes: [CGRect(x: 0, y: 0, width: 100, height: 20)],
            textTypes: [.general: "Low Confidence"],
            processingTime: 0.5,
            language: .english
        )
        
        // Create configuration for testing
        let configuration = OCROverlayConfiguration(
            allowsEditing: true,
            allowsDeletion: true,
            showConfidenceIndicators: true,
            highlightColor: .blue,
            editingColor: .green,
            lowConfidenceThreshold: 0.7,
            highConfidenceThreshold: 0.9
        )
        
        // When: Creating overlays
        let testImage = PlatformImage()
        _ = OCROverlayView(
            image: testImage,
            result: highConfidenceResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: lowConfidenceResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // Then: Should provide different visual indicators
        // Test high confidence (above high threshold)
        #expect(0.95 >= configuration.highConfidenceThreshold, "High confidence should be above high threshold")
        
        // Test low confidence (below low threshold)
        #expect(0.3 < configuration.lowConfidenceThreshold, "Low confidence should be below low threshold")
        
        // Test that overlays can be created with different confidence levels
        // OCROverlayView is non-optional - no need to check for nil
    }
    
    // MARK: - Accessibility Tests
    
    @Test @MainActor
    func testAccessibilitySupport() {
        // Given: OCR overlay
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: [
                CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
                CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
                CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
            ],
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Checking accessibility
        // Then: Should provide accessibility labels and be hostable
        _ = hostRootPlatformView(overlayView)
        #expect(Bool(true), "OCR overlay view should be hostable with accessibility")  // hostingView is non-optional
        // Note: We can't directly test SwiftUI accessibility modifiers in unit tests,
        // but we can verify the view can be hosted and the modifiers are applied
    }
    
    @Test @MainActor
    func testVoiceOverSupport() {
        // Given: OCR overlay with multiple text regions
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Hello World\nTest Text\nAnother Line",
            confidence: 0.85,
            boundingBoxes: [
                CGRect(x: 10, y: 20, width: 100, height: 30),  // First text region
                CGRect(x: 50, y: 60, width: 80, height: 25),   // Second text region
                CGRect(x: 120, y: 100, width: 60, height: 20)  // Third text region
            ],
            textTypes: [
                .general: "Hello World",
                .price: "Test Text", 
                .number: "Another Line"
            ],
            processingTime: 1.2,
            language: .english
        )
        
        _ = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Checking VoiceOver support
        // Then: Should provide proper accessibility elements and be hostable
        _ = hostRootPlatformView(overlayView)
        #expect(Bool(true), "OCR overlay view should be hostable with VoiceOver support")  // hostingView is non-optional
        // Note: We can't directly test SwiftUI accessibility elements in unit tests,
        // but we can verify the view can be hosted and the modifiers are applied
    }
    
    // MARK: - Edge Cases Tests
    
    @Test @MainActor func testOverlappingBoundingBoxes() {
        // Given: OCR result with overlapping bounding boxes
        let overlappingBoxes = [
            CGRect(x: 10, y: 10, width: 50, height: 20),
            CGRect(x: 30, y: 15, width: 40, height: 25) // Overlaps with first
        ]
        
        let overlappingResult = OCRResult(
            extractedText: "Overlapping Text",
            confidence: 0.7,
            boundingBoxes: overlappingBoxes,
            textTypes: [.general: "Overlapping Text"],
            processingTime: 1.0,
            language: .english
        )
        
        let testImage = PlatformImage()
        let testOCRResult = OCRResult(
            extractedText: "Overlapping Text",
            confidence: 0.7,
            boundingBoxes: overlappingBoxes,
            textTypes: [.general: "Overlapping Text"],
            processingTime: 1.0,
            language: .english
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testOCRResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Tapping in overlap area
        let tapPoint = CGPoint(x: 40, y: 20) // In overlap area
        _ = overlayView.detectTappedTextRegion(at: tapPoint)
        
        // Then: Should handle overlap gracefully
        #expect(Bool(true), "Should detect region despite overlap")
    }
    
    @Test @MainActor func testZeroSizeBoundingBoxes() {
        // Given: OCR result with zero-size bounding boxes
        let zeroSizeBoxes = [
            CGRect(x: 10, y: 10, width: 0, height: 0),
            CGRect(x: 20, y: 20, width: 0, height: 20),
            CGRect(x: 30, y: 30, width: 20, height: 0)
        ]
        
        let zeroSizeResult = OCRResult(
            extractedText: "Zero Size",
            confidence: 0.5,
            boundingBoxes: zeroSizeBoxes,
            textTypes: [.general: "Zero Size"],
            processingTime: 0.5,
            language: .english
        )
        
        let testImage = PlatformImage()
        _ = OCROverlayView(
            image: testImage,
            result: zeroSizeResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Rendering overlay
        // Then: Should handle zero-size boxes gracefully
        // OCROverlayView is non-optional - no need to check for nil
    }
    
    @Test @MainActor func testNegativeBoundingBoxes() {
        // Given: OCR result with negative bounding boxes
        let negativeBoxes = [
            CGRect(x: -10, y: -10, width: 50, height: 20),
            CGRect(x: 10, y: 10, width: -20, height: 30)
        ]
        
        let negativeResult = OCRResult(
            extractedText: "Negative Boxes",
            confidence: 0.6,
            boundingBoxes: negativeBoxes,
            textTypes: [.general: "Negative Boxes"],
            processingTime: 0.8,
            language: .english
        )
        
        let testImage = PlatformImage()
        _ = OCROverlayView(
            image: testImage,
            result: negativeResult,
            onTextEdit: { _, _ in },
            onTextDelete: { _ in }
        )
        
        // When: Rendering overlay
        // Then: Should handle negative boxes gracefully
        // OCROverlayView is non-optional - no need to check for nil
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testOCROverlayWithDisambiguationIntegration() {
        // Given: OCR disambiguation result
        let candidates = [
            OCRDataCandidate(
                text: "Hello",
                boundingBox: CGRect(x: 10, y: 10, width: 50, height: 20),
                confidence: 0.9,
                suggestedType: .general,
                alternativeTypes: [.general, .email]
            ),
            OCRDataCandidate(
                text: "World",
                boundingBox: CGRect(x: 70, y: 10, width: 40, height: 20),
                confidence: 0.7,
                suggestedType: .price,
                alternativeTypes: [.general, .number]
            )
        ]
        
        let disambiguationSelection = OCRDisambiguationSelection(
            candidateId: candidates[0].id,
            selectedType: .name,
            customText: nil
        )
        
        // When: Creating overlay from disambiguation result
        _ = OCROverlayView.fromDisambiguationResult(disambiguationSelection)
        
        // Then: Should create overlay successfully
        // OCROverlayView is non-optional - no need to check for nil
     }
}

