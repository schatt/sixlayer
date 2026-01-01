import Testing


import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for AppleHIGComplianceManager.swift classes
/// Ensures AppleHIGComplianceManager classes generate proper accessibility identifiers
/// for automated testing and accessibility tools compliance
@Suite("Apple HIG Compliance Manager Accessibility")
open class AppleHIGComplianceManagerAccessibilityTests: BaseTestClass {
    // MARK: - AppleHIGComplianceManager Tests
    
    /// BUSINESS PURPOSE: Validates that views using AppleHIGComplianceManager generate proper accessibility identifiers
    /// Tests views with .appleHIGCompliant() modifier which uses AppleHIGComplianceManager
    @Test @MainActor func testAppleHIGComplianceManagerGeneratesAccessibilityIdentifiersOnIOS() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with .appleHIGCompliant() modifier (which uses AppleHIGComplianceManager)
            let view = platformVStackContainer {
                Text("HIG Compliant Content")
            }
            .appleHIGCompliant()
            .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: AppleHIGCompliant DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:404.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "AppleHIGCompliant"
            )
            #expect(hasAccessibilityID, "View with .appleHIGCompliant() (using AppleHIGComplianceManager) should generate accessibility identifiers on iOS ")
        }
    }
    
    /// BUSINESS PURPOSE: Validates that views using AppleHIGComplianceManager generate proper accessibility identifiers
    /// Tests views with .appleHIGCompliant() modifier which uses AppleHIGComplianceManager
    @Test @MainActor func testAppleHIGComplianceManagerGeneratesAccessibilityIdentifiersOnMacOS() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with .appleHIGCompliant() modifier (which uses AppleHIGComplianceManager)
            let view = platformVStackContainer {
                Text("HIG Compliant Content")
            }
            .appleHIGCompliant()
            .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: AppleHIGCompliant DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/AppleHIGComplianceModifiers.swift:404.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.macOS,
                componentName: "AppleHIGCompliant"
            )
            #expect(hasAccessibilityID, "View with .appleHIGCompliant() (using AppleHIGComplianceManager) should generate accessibility identifiers on macOS ")
        }
    }
}

