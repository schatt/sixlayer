import Testing

import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for OCRService integration
/// Tests that views using OCRService generate proper accessibility identifiers
/// OCRService itself is a service class and doesn't generate views, but views that use it should
@Suite("OCR Service Accessibility")
open class OCRServiceAccessibilityTests: BaseTestClass {
        
    // MARK: - OCRService Integration Tests
    
    /// BUSINESS PURPOSE: Validates that views using OCRService generate proper accessibility identifiers
    /// Tests OCROverlayView which uses OCRService internally
    @Test @MainActor func testOCROverlayViewWithOCRServiceGeneratesAccessibilityIdentifiersOnIOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: OCROverlayView that uses OCRService internally
            let testImage = PlatformImage()
            let testResult = OCRResult(
                extractedText: "Test OCR Text",
                confidence: 0.95,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: 1.0,
                language: .english
            )
            
            // When: Creating OCROverlayView (which uses OCRService)
            let view = OCROverlayView(
                image: testImage,
                result: testResult,
                configuration: OCROverlayConfiguration(),
                onTextEdit: { _, _ in },
                onTextDelete: { _ in }
            )
            
            // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: OCROverlayView DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Views/OCROverlayView.swift:33.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*OCROverlayView.*",
                platform: SixLayerPlatform.iOS,
                componentName: "OCROverlayView"
            )
            #expect(hasAccessibilityID, "OCROverlayView (using OCRService) should generate accessibility identifiers on iOS ")
        }
    }
    
    /// BUSINESS PURPOSE: Validates that views using OCRService generate proper accessibility identifiers
    /// Tests OCROverlayView which uses OCRService internally
    @Test @MainActor func testOCROverlayViewWithOCRServiceGeneratesAccessibilityIdentifiersOnMacOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: OCROverlayView that uses OCRService internally
            let testImage = PlatformImage()
            let testResult = OCRResult(
                extractedText: "Test OCR Text",
                confidence: 0.95,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: 1.0,
                language: .english
            )
            
            // When: Creating OCROverlayView (which uses OCRService)
            let view = OCROverlayView(
                image: testImage,
                result: testResult,
                configuration: OCROverlayConfiguration(),
                onTextEdit: { _, _ in },
                onTextDelete: { _ in }
            )
            
            // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: OCROverlayView DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Views/OCROverlayView.swift:33.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*OCROverlayView.*",
                platform: SixLayerPlatform.macOS,
                componentName: "OCROverlayView"
            )
            #expect(hasAccessibilityID, "OCROverlayView (using OCRService) should generate accessibility identifiers on macOS ")
        }
    }
    
}
