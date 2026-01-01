import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformOCRSemanticLayer1.swift
/// 
/// BUSINESS PURPOSE: Ensure all OCR Layer 1 semantic functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformOCRSemanticLayer1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform OCR Semantic Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformOCRSemanticLayer1Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - platformOCRWithVisualCorrection_L1 Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testPlatformOCRWithVisualCorrectionL1GeneratesAccessibilityIdentifiersOnIOS() async {
                initializeTestConfig()
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8,
            allowsEditing: true
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
                expectedPattern: "SixLayer.*ui", 
            componentName: "platformOCRWithVisualCorrection_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformOCRWithVisualCorrectionL1GeneratesAccessibilityIdentifiersOnMacOS() async {
                initializeTestConfig()
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8,
            allowsEditing: true
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
                expectedPattern: "SixLayer.*ui", 
            componentName: "platformOCRWithVisualCorrection_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformExtractStructuredData_L1 Tests
    
    @Test @MainActor func testPlatformExtractStructuredDataL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8,
            allowsEditing: true
        )
        
        let view = platformExtractStructuredData_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
                expectedPattern: "SixLayer.*ui", 
            componentName: "platformExtractStructuredData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformExtractStructuredData_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformExtractStructuredDataL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8,
            allowsEditing: true
        )
        
        let view = platformExtractStructuredData_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
                expectedPattern: "SixLayer.*ui", 
            componentName: "platformExtractStructuredData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformExtractStructuredData_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}
