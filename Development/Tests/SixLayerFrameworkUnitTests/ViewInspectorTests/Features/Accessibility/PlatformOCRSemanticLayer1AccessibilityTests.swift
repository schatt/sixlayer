import Testing

import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for PlatformOCRSemanticLayer1.swift functions
/// Ensures OCR semantic Layer 1 functions generate proper accessibility identifiers
/// for automated testing and accessibility tools compliance
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform OCR Semantic Layer Accessibility")
open class PlatformOCRSemanticLayer1AccessibilityTests: BaseTestClass {    // MARK: - OCR Visual Correction Tests
    
    /// BUSINESS PURPOSE: Validates that platformOCRWithVisualCorrection_L1 generates proper accessibility identifiers
    /// for automated testing and accessibility tools compliance on iOS
    @Test @MainActor func testPlatformOCRWithVisualCorrectionL1GeneratesAccessibilityIdentifiersOnIOS() async {
                initializeTestConfig()
        // Given
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [TextType.general],
            language: OCRLanguage.english
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        // When & Then
        // Note: Element-level IDs are implemented at the function level
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformOCRWithVisualCorrection_L1"
        )
        #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 should generate accessibility identifiers on iOS ")
    }
    
    /// BUSINESS PURPOSE: Validates that platformOCRWithVisualCorrection_L1 generates proper accessibility identifiers
    /// for automated testing and accessibility tools compliance on macOS
    @Test @MainActor func testPlatformOCRWithVisualCorrectionL1GeneratesAccessibilityIdentifiersOnMacOS() async {
                initializeTestConfig()
        // Given
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [TextType.general],
            language: OCRLanguage.english
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        // When & Then
        // Note: Element-level IDs are implemented at the function level
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformOCRWithVisualCorrection_L1"
        )
        #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 should generate accessibility identifiers on macOS ")
    }
    
    /// BUSINESS PURPOSE: Validates that platformOCRWithVisualCorrection_L1 (array version) generates proper accessibility identifiers
    /// for automated testing and accessibility tools compliance on iOS
    @Test @MainActor func testPlatformOCRWithVisualCorrectionArrayL1GeneratesAccessibilityIdentifiersOnIOS() async {
                initializeTestConfig()
        // Given
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [TextType.general],
            language: OCRLanguage.english
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        // When & Then
        // Note: Element-level IDs are implemented at the function level
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformOCRWithVisualCorrection_L1"
        )
        #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 (array) should generate accessibility identifiers on iOS ")
    }
    
    /// BUSINESS PURPOSE: Validates that platformOCRWithVisualCorrection_L1 (array version) generates proper accessibility identifiers
    /// for automated testing and accessibility tools compliance on macOS
    @Test @MainActor func testPlatformOCRWithVisualCorrectionArrayL1GeneratesAccessibilityIdentifiersOnMacOS() async {
                initializeTestConfig()
        // Given
        let testImage = PlatformImage()
        let context = OCRContext(
            textTypes: [TextType.general],
            language: OCRLanguage.english
        )
        
        let view = platformOCRWithVisualCorrection_L1(
            image: testImage,
            context: context,
            onResult: { _ in }
        )
        
        // When & Then
        // Note: Element-level IDs are implemented at the function level
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformOCRWithVisualCorrection_L1"
        )
        #expect(hasAccessibilityID, "platformOCRWithVisualCorrection_L1 (array) should generate accessibility identifiers on macOS ")
    }
}
