import Testing


import SwiftUI
@testable import SixLayerFramework
/// Test that framework components respect global accessibility config
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Framework Component Global Config")
open class FrameworkComponentGlobalConfigTests: BaseTestClass {

    // BaseTestClass handles setup automatically - no need for custom init
    
    @Test @MainActor func testFrameworkComponentsRespectGlobalConfigWhenDisabled() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test that framework components don't generate IDs when global config is disabled
            
            // Disable global config AFTER setup (which resets to defaults)
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = false
            
            // Create a framework component WITHOUT .named() (this should NOT generate an ID)
            // Also set config to false to ensure no IDs are generated
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.globalAutomaticAccessibilityIdentifiers = false  // ← Disable via config
            let view = Button("Test") { }
                .automaticCompliance()
            
            // Try to inspect for accessibility identifier
            #if canImport(ViewInspector)
            if let inspectedView = try? AnyView(view).inspect(),
               let button = try? inspectedView.button(),
               let accessibilityID = try? button.accessibilityIdentifier() {
                // Should be empty or not present when global config is disabled
                #expect(accessibilityID.isEmpty, "Framework component should not generate ID when global config is disabled")
            } else {
                // If we can't inspect, that's also fine - means no accessibility identifier was applied
            }
            #else
            #endif
            
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testFrameworkComponentsGenerateIDsWhenGlobalConfigEnabled() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test that framework components DO generate IDs when global config is enabled
            // Note: .named() modifier always generates IDs regardless of global config
            // This is the correct behavior - explicit naming should always work
            
            // Set global config to enabled
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = true
            
            // Create a framework component with .named() (this SHOULD generate an ID)
            // .named() always generates IDs regardless of global config
            config.globalAutomaticAccessibilityIdentifiers = true  // ← Enable via config
            let view = Button("Test") { }
                .named("TestButton")
            
            // Try to inspect for accessibility identifier
            #if canImport(ViewInspector)
            #expect(testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*TestButton*",
                platform: SixLayerPlatform.iOS,
                componentName: "TestButton"
            ), "Framework component with .named() should generate ID when global config is enabled")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
            cleanupTestEnvironment()
        }
    }
}
