import Testing
import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformInternationalizationL1.swift
/// 
/// BUSINESS PURPOSE: Ensure all internationalization Layer 1 functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformInternationalizationL1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Internationalization L")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformInternationalizationL1Tests: BaseTestClass {
    
@Test @MainActor func testPlatformPresentLocalizedContentL1GeneratesAccessibilityIdentifiersOnIOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedContent_L1(
                content: platformPresentContent_L1(content: "Test Localized Content", hints: PresentationHints()),
                hints: hints
            )
        
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedContent_L1 should generate accessibility identifiers on iOS ")
        }
    }

    
    @Test @MainActor func testPlatformPresentLocalizedContentL1GeneratesAccessibilityIdentifiersOnMacOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedContent_L1(
                content: platformPresentContent_L1(content: "Test Localized Content", hints: PresentationHints()),
                hints: hints
            )
        
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedContent_L1 should generate accessibility identifiers on macOS ")
        }
    }

    
    // MARK: - platformPresentLocalizedText_L1 Tests
    
    @Test @MainActor func testPlatformPresentLocalizedTextL1GeneratesAccessibilityIdentifiersOnIOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedText_L1(text: "Test Localized Text", hints: hints)
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedText_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedText_L1 should generate accessibility identifiers on iOS ")
        }
    }

    
    @Test @MainActor func testPlatformPresentLocalizedTextL1GeneratesAccessibilityIdentifiersOnMacOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedText_L1(text: "Test Localized Text", hints: hints)
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedText_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedText_L1 should generate accessibility identifiers on macOS ")
        }
    }

}
