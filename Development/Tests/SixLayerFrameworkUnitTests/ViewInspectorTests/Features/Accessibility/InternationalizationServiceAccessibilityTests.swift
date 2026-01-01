import Testing


import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for InternationalizationService.swift classes
/// Ensures InternationalizationService classes generate proper accessibility identifiers
/// for automated testing and accessibility tools compliance
@Suite("Internationalization Service Accessibility")
open class InternationalizationServiceAccessibilityTests: BaseTestClass {
    
    // MARK: - InternationalizationService Tests
    
    /// BUSINESS PURPOSE: Validates that views using InternationalizationService generate proper accessibility identifiers
    /// Tests PlatformInternationalizationL1 functions which use InternationalizationService
    @Test @MainActor func testInternationalizationServiceGeneratesAccessibilityIdentifiersOnIOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view using platformPresentLocalizedContent_L1 (which uses InternationalizationService)
            let view = platformPresentLocalizedContent_L1(
                content: Text("Localized Content"),
                hints: InternationalizationHints()
            )
            
            // When & Then: Should generate accessibility identifiers
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*platformPresentLocalizedContent_L1.*",
                platform: SixLayerPlatform.iOS,
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "View with platformPresentLocalizedContent_L1 (using InternationalizationService) should generate accessibility identifiers on iOS ")
        }
    }
    
    /// BUSINESS PURPOSE: Validates that views using InternationalizationService generate proper accessibility identifiers
    /// Tests PlatformInternationalizationL1 functions which use InternationalizationService
    @Test @MainActor func testInternationalizationServiceGeneratesAccessibilityIdentifiersOnMacOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view using platformPresentLocalizedContent_L1 (which uses InternationalizationService)
            let view = platformPresentLocalizedContent_L1(
                content: Text("Localized Content"),
                hints: InternationalizationHints()
            )
            
            // When & Then: Should generate accessibility identifiers
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*platformPresentLocalizedContent_L1.*",
                platform: SixLayerPlatform.macOS,
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "View with platformPresentLocalizedContent_L1 (using InternationalizationService) should generate accessibility identifiers on macOS ")
        }
    }
}
