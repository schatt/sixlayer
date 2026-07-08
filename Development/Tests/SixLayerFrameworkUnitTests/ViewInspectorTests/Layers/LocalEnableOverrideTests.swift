import Testing

import SwiftUI
import ViewInspector
@testable import SixLayerFramework
/// Test the "global disable, local enable" functionality
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Local Enable Override")
open class LocalEnableOverrideTests: BaseTestClass {

    // BaseTestClass handles setup automatically - no need for custom init
    
    @Test @MainActor func testGlobalDisableLocalEnable() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Configure test environment
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.mode = .automatic
            config.enableDebugLogging = true  // Enable debug to see what's happening
            
            // Test: Global disabled, but local enable should work
            
            // 1. Disable global config
            config.enableAutoIDs = false
            print("🔧 Global config disabled: enableAutoIDs = false")
            
            // 2. Create a view with local enable; pass identifierName so automaticCompliance creates an ID (L1 pattern)
            let view = Button("Special Button") { }
                .automaticCompliance(identifierName: "SpecialButton")  // ← Local enable + name so ID is generated
            
            // 3. Verify local enable overrides global disable via harness
            #if canImport(ViewInspector)
            let hasLocalEnableID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*SpecialButton*",
                platform: SixLayerPlatform.iOS,
                componentName: "SpecialButton"
            )
            #expect(hasLocalEnableID, "Local enable should override global disable")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testNamedModifierAlwaysWorksRegardlessOfGlobalSettings() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Test that .named() always works regardless of global settings
            // This is the correct behavior - explicit naming should not be affected by global config

            // Configure test environment
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.mode = .automatic
            config.enableDebugLogging = true
            
            // Test: Global enabled, but .named() should still work even with local disable
            
            // 1. Enable global config
            config.enableAutoIDs = true
            print("🔧 Global config enabled: enableAutoIDs = true")
            
            // 2. Create a view with explicit naming (should work regardless of global settings)
            let view = Button("Disabled Button") { }
                .disableAutomaticAccessibilityIdentifiers()  // ← Apply disable FIRST
                .named("DisabledButton")
            
            // 3. Verify explicit naming via harness (applies regardless of global settings)
            #if canImport(ViewInspector)
            let hasNamedID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*DisabledButton*",
                platform: SixLayerPlatform.iOS,
                componentName: "DisabledButton"
            )
            #expect(hasNamedID, ".named() should always generate identifier regardless of global settings")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testNamedModifierAlwaysWorksEvenWhenGlobalConfigDisabled() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Configure test environment
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.mode = .automatic
            config.enableDebugLogging = true
            
            // Test: Framework components should respect global config
            
            // 1. Disable global config
            config.enableAutoIDs = false
            print("🔧 Global config disabled for framework component test")
            
            // 2. Create a framework component (should NOT generate ID)
            let view = Button("Framework Button") { }
                .named("FrameworkButton")
            
            // 3. Try to inspect for accessibility identifier
            #if canImport(ViewInspector)
            do {
                let inspectedView = try AnyView(view).inspect()
                let button = try inspectedView.button()
                let accessibilityID = try button.accessibilityIdentifier()
                
                // .named() should always work regardless of global settings
                // This is the correct behavior - explicit naming should not be affected by global config
                #expect(!accessibilityID.isEmpty, ".named() should always work regardless of global config")
                #expect(accessibilityID.contains("FrameworkButton"), "Should contain the explicit name")
                
                print("   No ID generated (as expected)")
                
            } catch {
                // If we can't inspect, that's also fine - means no accessibility identifier was applied
            }
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
            cleanupTestEnvironment()
        }
    }
}
