import Testing


import SwiftUI
@testable import SixLayerFramework
/// BUSINESS PURPOSE: Accessibility tests for SwitchControlManager.swift classes
/// Ensures SwitchControlManager classes generate proper accessibility identifiers
/// for automated testing and accessibility tools compliance
@Suite("Switch Control Manager Accessibility")
open class SwitchControlManagerAccessibilityTests: BaseTestClass {
    
    // MARK: - SwitchControlManager Tests
    
    /// BUSINESS PURPOSE: Validates that views using SwitchControlManager generate proper accessibility identifiers
    /// Tests views with .switchControlEnabled() modifier which uses SwitchControlManager
    @Test @MainActor func testSwitchControlManagerGeneratesAccessibilityIdentifiersOnIOS() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with .switchControlEnabled() modifier (which uses SwitchControlManager)
            let view = Button("Test Button") { }
                .switchControlEnabled()
                .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: SwitchControlEnabled DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/SwitchControlManager.swift:358.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.iOS,
                componentName: "SwitchControlEnabled"
            )
            #expect(hasAccessibilityID, "View with .switchControlEnabled() (using SwitchControlManager) should generate accessibility identifiers on iOS ")
        }
    }
    
    /// BUSINESS PURPOSE: Validates that views using SwitchControlManager generate proper accessibility identifiers
    /// Tests views with .switchControlEnabled() modifier which uses SwitchControlManager
    @Test @MainActor func testSwitchControlManagerGeneratesAccessibilityIdentifiersOnMacOS() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Given: A view with .switchControlEnabled() modifier (which uses SwitchControlManager)
            let view = Button("Test Button") { }
                .switchControlEnabled()
                .automaticCompliance()
            
            // When & Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: SwitchControlEnabled DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Extensions/Accessibility/SwitchControlManager.swift:358.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "SixLayer.main.ui.*",
                platform: SixLayerPlatform.macOS,
                componentName: "SwitchControlEnabled"
            )
            #expect(hasAccessibilityID, "View with .switchControlEnabled() (using SwitchControlManager) should generate accessibility identifiers on macOS ")
        }
    }
}

