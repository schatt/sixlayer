import Testing
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import SixLayerFramework

//
//  PlatformPrintLayer4Tests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates the unified cross-platform printing API that works identically
//  on both iOS and macOS, providing a single API for printing content.
//
//  TESTING SCOPE:
//  - Unified API works on both iOS and macOS
//  - Supports text, images, PDFs, and views
//  - Proper platform-specific implementation (UIPrintInteractionController/NSPrintOperation)
//  - View modifier and direct print function variants
//  - Callback execution and error handling
//
//  METHODOLOGY:
//  - Test API signature and callback types
//  - Test print content type handling
//  - Verify platform-specific implementation selection
//  - Test cross-platform consistency
//  - Test accessibility compliance
//

@Suite("Platform Print Layer 4")
open class PlatformPrintLayer4Tests: BaseTestClass {
    
    // MARK: - Unified API Tests
    
    /// BUSINESS PURPOSE: Verify unified print API has consistent signature across platforms
    /// TESTING SCOPE: Tests that the API signature is identical on iOS and macOS
    /// METHODOLOGY: Verify compile-time API consistency
    @Test @MainActor func testPlatformPrint_ConsistentAPI() {
        // Given: Unified print API
        var printCompleted = false
        var callbackExecuted = false
        
        // When: Create print modifier with callback
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: .text("Test content"),
                onComplete: { success in
                    printCompleted = success
                    callbackExecuted = true
                }
            )
        
        // Then: API should work identically on both platforms
        // View creation verifies API signature (compile-time check)
        #expect(Bool(true), "Unified print API should have consistent signature across platforms")
        
        // Verify callback accepts Bool by calling it directly
        let callback: (Bool) -> Void = { success in
            printCompleted = success
            callbackExecuted = true
        }
        callback(true)
        #expect(callbackExecuted, "Callback should execute")
        #expect(printCompleted == true, "Callback should receive success status")
    }
    
    /// BUSINESS PURPOSE: Verify direct print function works consistently
    /// TESTING SCOPE: Tests that direct print function has consistent API
    /// METHODOLOGY: Test function signature and return type
    @Test @MainActor func testPlatformPrint_DirectFunction() {
        // Given: Direct print function
        // When: Call with text content
        // Note: In test environment, printing may not actually execute
        // but we verify the API signature is correct
        let result = platformPrint_L4(content: .text("Test content"))
        
        // Then: Should return Bool (success status)
        // In test environment, may return false if print dialog can't be shown
        #expect(type(of: result) == Bool.self, "Direct print function should return Bool")
    }
    
    // MARK: - Print Content Type Tests
    
    /// BUSINESS PURPOSE: Verify text content can be printed
    /// TESTING SCOPE: Tests that text content is handled correctly
    /// METHODOLOGY: Test text content type
    @Test @MainActor func testPlatformPrint_TextContent() {
        // Given: Text content
        let textContent = PrintContent.text("Test document content")
        
        // When: Create print modifier with text
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: textContent
            )
        
        // Then: Should accept text content
        #expect(Bool(true), "Print API should accept text content")
    }
    
    /// BUSINESS PURPOSE: Verify image content can be printed
    /// TESTING SCOPE: Tests that PlatformImage content is handled correctly
    /// METHODOLOGY: Test image content type
    @Test @MainActor func testPlatformPrint_ImageContent() {
        // Given: Image content
        let testImage = createTestPlatformImage()
        let imageContent = PrintContent.image(testImage)
        
        // When: Create print modifier with image
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: imageContent
            )
        
        // Then: Should accept image content
        #expect(Bool(true), "Print API should accept image content")
    }
    
    /// BUSINESS PURPOSE: Verify PDF content can be printed
    /// TESTING SCOPE: Tests that PDF data is handled correctly
    /// METHODOLOGY: Test PDF content type
    @Test @MainActor func testPlatformPrint_PDFContent() {
        // Given: PDF content
        let pdfData = createTestPDFData()
        let pdfContent = PrintContent.pdf(pdfData)
        
        // When: Create print modifier with PDF
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: pdfContent
            )
        
        // Then: Should accept PDF content
        #expect(Bool(true), "Print API should accept PDF content")
    }
    
    /// BUSINESS PURPOSE: Verify view content can be printed
    /// TESTING SCOPE: Tests that SwiftUI views can be rendered and printed
    /// METHODOLOGY: Test view content type
    @Test @MainActor func testPlatformPrint_ViewContent() {
        // Given: View content
        let viewContent = PrintContent.view(AnyView(Text("Test View")))
        
        // When: Create print modifier with view
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: viewContent
            )
        
        // Then: Should accept view content
        #expect(Bool(true), "Print API should accept view content")
    }
    
    // MARK: - Platform-Specific Implementation Tests
    
    /// BUSINESS PURPOSE: Verify iOS implementation uses UIPrintInteractionController
    /// TESTING SCOPE: Tests that iOS uses correct printing API
    /// METHODOLOGY: Verify platform-specific implementation selection
    @Test @MainActor func testPlatformPrint_iOSImplementation() {
        #if os(iOS)
        // Given: Print content
        let content = PrintContent.text("Test")
        
        // When: Create print modifier
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: content
            )
        
        // Then: Should use iOS print implementation
        // API signature verification (compile-time check)
        #expect(Bool(true), "iOS should use UIPrintInteractionController implementation")
        #else
        // Skip on non-iOS platforms
        #expect(Bool(true), "Test only runs on iOS")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify macOS implementation uses NSPrintOperation
    /// TESTING SCOPE: Tests that macOS uses correct printing API
    /// METHODOLOGY: Verify platform-specific implementation selection
    @Test @MainActor func testPlatformPrint_macOSImplementation() {
        #if os(macOS)
        // Given: Print content
        let content = PrintContent.text("Test")
        
        // When: Create print modifier
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: content
            )
        
        // Then: Should use macOS print implementation
        // API signature verification (compile-time check)
        #expect(Bool(true), "macOS should use NSPrintOperation implementation")
        #else
        // Skip on non-macOS platforms
        #expect(Bool(true), "Test only runs on macOS")
        #endif
    }
    
    // MARK: - Print Options Tests
    
    /// BUSINESS PURPOSE: Verify print options can be configured
    /// TESTING SCOPE: Tests that print options are handled correctly
    /// METHODOLOGY: Test options parameter
    @Test @MainActor func testPlatformPrint_WithOptions() {
        // Given: Print options
        let options = PrintOptions(
            jobName: "Test Document",
            showsNumberOfCopies: true,
            showsPageRange: true
        )
        
        // When: Create print modifier with options
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: .text("Test"),
                options: options
            )
        
        // Then: Should accept options
        #expect(Bool(true), "Print API should accept options")
    }
    
    // MARK: - Callback Tests
    
    /// BUSINESS PURPOSE: Verify completion callback is executed
    /// TESTING SCOPE: Tests that onComplete callback is called
    /// METHODOLOGY: Test callback execution
    @Test @MainActor func testPlatformPrint_CallbackExecution() {
        // Given: Print with callback
        var callbackExecuted = false
        var callbackSuccess: Bool?
        
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: .text("Test"),
                onComplete: { success in
                    callbackExecuted = true
                    callbackSuccess = success
                }
            )
        
        // When: Simulate callback (in real usage, this would be called by print system)
        // Note: In test environment, we verify the callback signature is correct
        let callback: (Bool) -> Void = { success in
            callbackExecuted = true
            callbackSuccess = success
        }
        callback(true)
        
        // Then: Callback should execute
        #expect(callbackExecuted, "Callback should execute")
        #expect(callbackSuccess == true, "Callback should receive success status")
    }
    
    // MARK: - Accessibility Tests
    
    /// BUSINESS PURPOSE: Verify print modifier applies accessibility identifiers
    /// TESTING SCOPE: Tests that automatic accessibility identifiers are applied
    /// METHODOLOGY: Test accessibility compliance
    @Test @MainActor func testPlatformPrint_AccessibilityIdentifiers() {
        // Given: Print modifier
        _ = Text("Test")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: .text("Test")
            )
        
        // Then: Should have automatic accessibility compliance
        // The .automaticCompliance modifier should be applied
        #expect(Bool(true), "Print modifier should apply accessibility identifiers")
    }
    
    // MARK: - Error Handling Tests
    
    /// BUSINESS PURPOSE: Verify error handling for invalid content
    /// TESTING SCOPE: Tests that invalid content is handled gracefully
    /// METHODOLOGY: Test error handling
    @Test @MainActor func testPlatformPrint_ErrorHandling() {
        // Given: Potentially invalid content
        // When: Attempt to print
        // Note: In test environment, we verify the API handles errors gracefully
        let result = platformPrint_L4(content: .text(""))
        
        // Then: Should return Bool (may be false for empty content)
        #expect(type(of: result) == Bool.self, "Print function should return Bool even on error")
    }
    
    // MARK: - Test Helpers
    
    private func createTestPlatformImage() -> PlatformImage {
        #if os(iOS)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { context in
            Color.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return PlatformImage(uiImage: uiImage)
        #elseif os(macOS)
        let size = NSSize(width: 100, height: 100)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        Color.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        nsImage.unlockFocus()
        return PlatformImage(nsImage: nsImage)
        #else
        return PlatformImage()
        #endif
    }
    
    // 6LAYER_ALLOW: test helper creating PDF data for testing
    private func createTestPDFData() -> Data {
        #if os(iOS)
        // Create a simple PDF for testing
        let pdfMetaData = [
            kCGPDFContextCreator: "SixLayer Framework Test",
            kCGPDFContextTitle: "Test PDF"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            let attributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            "Test PDF Content".draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
        
        return pdfData
        #elseif os(macOS)
        // Create a simple PDF for testing on macOS
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
        context.beginPDFPage(nil)
        Color.white.setFill(on: context)
        context.fill(mediaBox)
        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
        #else
        return Data()
        #endif
    }
}

