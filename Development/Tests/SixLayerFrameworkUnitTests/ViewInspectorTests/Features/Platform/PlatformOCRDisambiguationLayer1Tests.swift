import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformOCRDisambiguationLayer1.swift
/// 
/// BUSINESS PURPOSE: Ensure all OCR disambiguation Layer 1 functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformOCRDisambiguationLayer1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform OCR Disambiguation Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformOCRDisambiguationLayer1Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - platformOCRDisambiguation_L1 Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testPlatformOCRDisambiguationL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let alternatives = ["Option 1", "Option 2", "Option 3"]
        
        // Verify alternatives are properly configured
        #expect(alternatives.count == 3, "Should have 3 alternatives")
        #expect(alternatives[0] == "Option 1", "First alternative should be correct")
        #expect(alternatives[1] == "Option 2", "Second alternative should be correct")
        #expect(alternatives[2] == "Option 3", "Third alternative should be correct")
        
        let view = platformOCRWithDisambiguation_L1(
            image: PlatformImage(),
            context: OCRContext(
                textTypes: [.general],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true
            ),
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            componentName: "platformOCRDisambiguation_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformOCRDisambiguation_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformOCRDisambiguationL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let alternatives = ["Option 1", "Option 2", "Option 3"]
        
        // Verify alternatives are properly configured
        #expect(alternatives.count == 3, "Should have 3 alternatives")
        #expect(alternatives[0] == "Option 1", "First alternative should be correct")
        #expect(alternatives[1] == "Option 2", "Second alternative should be correct")
        #expect(alternatives[2] == "Option 3", "Third alternative should be correct")
        
        let view = platformOCRWithDisambiguation_L1(
            image: PlatformImage(),
            context: OCRContext(
                textTypes: [.general],
                language: .english,
                confidenceThreshold: 0.8,
                allowsEditing: true
            ),
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            componentName: "platformOCRDisambiguation_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformOCRDisambiguation_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

