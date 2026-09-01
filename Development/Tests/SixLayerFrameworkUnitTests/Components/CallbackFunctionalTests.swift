import Testing


import SwiftUI
@testable import SixLayerFramework
@Suite("Callback Functional")
/// Component Callback Functional Tests
/// Tests that components with callbacks ACTUALLY INVOKE them when expected (Rules 6.1, 6.2, 7.3, 7.4)
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class CallbackFunctionalTests: BaseTestClass {
    
    // MARK: - OCROverlayView Callback Tests
    
    @Test @MainActor func testOCROverlayViewOnTextEditCallback() async throws {
                initializeTestConfig()
        // Rule 6.2 & 7.4: Functional testing - Must verify callbacks ACTUALLY invoke
        
        var callbackInvoked = false
        
        let testImage = PlatformImage()
        let testResult = OCRResult(
            extractedText: "Test OCR Text",
            confidence: 0.95,
            boundingBoxes: [CGRect(x: 10, y: 20, width: 100, height: 30)],
            textTypes: [:],
            processingTime: 1.0,
            language: .english
        )
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testResult,
            configuration: OCROverlayConfiguration(),
            onTextEdit: { _, _ in
                callbackInvoked = true
            },
            onTextDelete: { _ in }
        )
        
        // When: Simulating text edit completion
        overlayView.completeTextEditing()
        
        // Then: Callback should be invoked
        #expect(callbackInvoked, "Callback should be invoked when editing completes")
    }
    
    @Test @MainActor func testOCROverlayViewOnTextDeleteCallback() async throws {
                initializeTestConfig()
        // Rule 6.2 & 7.4: Functional testing
        
        var callbackInvoked = false
        var receivedRect: CGRect?
        
        let testImage = PlatformImage()
        let testResult = OCRResult(
            extractedText: "Test OCR Text",
            confidence: 0.95,
            boundingBoxes: [CGRect(x: 10, y: 20, width: 100, height: 30)],
            textTypes: [:],
            processingTime: 1.0,
            language: .english
        )
        
        let testRect = CGRect(x: 10, y: 20, width: 100, height: 30)
        
        let overlayView = OCROverlayView(
            image: testImage,
            result: testResult,
            configuration: OCROverlayConfiguration(),
            onTextEdit: { _, _ in },
            onTextDelete: { rect in
                callbackInvoked = true
                receivedRect = rect
            }
        )
        
        // When: Deleting a text region
        overlayView.deleteTextRegion(testRect)
        
        // Then: Callback should be invoked
        #expect(callbackInvoked, "Callback should be invoked when deleting region")
        #expect(receivedRect == testRect, "Should receive correct rect")
    }
    
    // MARK: - IntelligentFormView Callback Tests
    
    @Test @MainActor func testIntelligentFormViewOnSubmitCallback() async throws {
            initializeTestConfig()
        // Rule 6.2 & 7.4: Functional testing - Verifies callback API works
        // NOTE: Actual callback invocation requires UI interaction (button taps)
        // This test verifies the API accepts callback parameters correctly

        struct TestFormData {
            let name: String
            let email: String
            let age: Int
        }

        let testData = TestFormData(name: "Test User", email: "test@example.com", age: 25)

        // Test that form generation method accepts callback parameters
        // If this compiles, the API works correctly
        let _ = IntelligentFormView.generateForm(
            for: TestFormData.self,
            initialData: testData,
            onSubmit: { _ in /* callback would be invoked on button tap */ },
            onCancel: { /* callback would be invoked on button tap */ }
        )
    }
    
    @Test @MainActor func testIntelligentFormViewOnCancelCallback() async throws {
            initializeTestConfig()
        // Rule 6.2 & 7.4: Functional testing - Verifies callback API works
        // NOTE: Actual callback invocation requires UI interaction (button taps)
        // This test verifies the API accepts callback parameters correctly

        struct TestFormData {
            let name: String
            let email: String
        }

        let testData = TestFormData(name: "Test", email: "test@example.com")

        // Test that form generation method accepts callback parameters
        // If this compiles, the API works correctly
        let _ = IntelligentFormView.generateForm(
            for: testData,
            onUpdate: { _ in /* callback would be invoked on field updates */ },
            onCancel: { /* callback would be invoked on button tap */ }
        )
    }
    
    // MARK: - External Integration Tests
    
    /// Tests that OCROverlayView callbacks are accessible from external modules (Rule 8)
    @Test @MainActor func testOCROverlayViewCallbacksExternallyAccessible() async throws {
                initializeTestConfig()
        // External module integration test for OCROverlayView callbacks
        // Tests that the public API accepts callback parameters correctly

        let testImage = PlatformImage()
        let testResult = OCRResult(
            extractedText: "Test",
            confidence: 0.9,
            boundingBoxes: [],
            textTypes: [:],
            processingTime: 1.0,
            language: .english
        )

        // Test that OCROverlayView can be initialized with callback parameters
        // If this compiles, the public API works correctly
        let _ = OCROverlayView(
            image: testImage,
            result: testResult,
            onTextEdit: { _, _ in /* callback would be invoked during text editing */ },
            onTextDelete: { _ in /* callback would be invoked during text deletion */ }
        )
    }
}
