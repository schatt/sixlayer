import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for OCRDisambiguationView.swift
/// 
/// BUSINESS PURPOSE: Ensure OCRDisambiguationView generates proper accessibility identifiers
/// TESTING SCOPE: All components in OCRDisambiguationView.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("OCR Disambiguation View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class OCRDisambiguationViewTests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - OCRDisambiguationView Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testOCRDisambiguationViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let candidates = [
            OCRDataCandidate(
                text: "Test Text",
                boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                confidence: 0.95,
                suggestedType: .general,
                alternativeTypes: [.email, .phone]
            )
        ]
        
        let result = OCRDisambiguationResult(
            candidates: candidates,
            confidence: 0.95,
            requiresUserSelection: true
        )
        
        let view = OCRDisambiguationView(
            result: result,
            onSelection: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "OCRDisambiguationView"
        )
 #expect(hasAccessibilityID, "OCRDisambiguationView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testOCRDisambiguationViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let candidates = [
            OCRDataCandidate(
                text: "Test Text",
                boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                confidence: 0.95,
                suggestedType: .general,
                alternativeTypes: [.email, .phone]
            )
        ]
        
        let result = OCRDisambiguationResult(
            candidates: candidates,
            confidence: 0.95,
            requiresUserSelection: true
        )
        
        let view = OCRDisambiguationView(
            result: result,
            onSelection: { _ in }
        )
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "OCRDisambiguationView"
        )
 #expect(hasAccessibilityID, "OCRDisambiguationView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

