import Testing


import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for EyeTrackingManager.swift classes
/// Ensures EyeTrackingManager classes generate proper accessibility identifiers
/// for automated testing and accessibility tools compliance
@Suite("Eye Tracking Manager Accessibility")
open class EyeTrackingManagerAccessibilityTests: BaseTestClass {
    
    // MARK: - EyeTrackingManager Tests
    
    /// BUSINESS PURPOSE: Validates that views using EyeTrackingManager generate proper accessibility identifiers
    /// Tests views with EyeTrackingModifier which uses EyeTrackingManager internally
    @Test @MainActor func testEyeTrackingManagerGeneratesAccessibilityIdentifiersOnIOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with EyeTrackingModifier (which uses EyeTrackingManager)
            let view = platformVStackContainer {
                Text("Eye Tracking Content")
            }
            .eyeTrackingEnabled()
            .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: EyeTrackingModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/EyeTrackingManager.swift:367.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "EyeTrackingModifier"
            )
            #expect(hasAccessibilityID, "View with EyeTrackingModifier (using EyeTrackingManager) should generate accessibility identifiers on iOS ")
        }
    }
    
    /// BUSINESS PURPOSE: Validates that views using EyeTrackingManager generate proper accessibility identifiers
    /// Tests views with EyeTrackingModifier which uses EyeTrackingManager internally
    @Test @MainActor func testEyeTrackingManagerGeneratesAccessibilityIdentifiersOnMacOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with EyeTrackingModifier (which uses EyeTrackingManager)
            let view = platformVStackContainer {
                Text("Eye Tracking Content")
            }
            .eyeTrackingEnabled()
            .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: EyeTrackingModifier DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/EyeTrackingManager.swift:367.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.macOS,
                componentName: "EyeTrackingModifier"
            )
            #expect(hasAccessibilityID, "View with EyeTrackingModifier (using EyeTrackingManager) should generate accessibility identifiers on macOS ")
        }
    }
}
