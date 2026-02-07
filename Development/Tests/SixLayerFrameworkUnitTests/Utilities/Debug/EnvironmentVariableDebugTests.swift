import Testing
#if canImport(ViewInspector)
import ViewInspector
#endif
import SwiftUI
@testable import SixLayerFramework
/// Debug test to understand environment variable propagation
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Environment Variable Debug")
open class EnvironmentVariableDebugTests: BaseTestClass {

    // BaseTestClass handles setup automatically - no need for custom init
    
    @Test @MainActor func testEnvironmentVariablePropagation() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            
            // Test: Does the environment variable get set properly?
            
            // 1. Disable global config
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false
            print("🔧 Global config disabled: enableAutoIDs = false")
            
            // 2. Create a view with automaticAccessibilityIdentifiers modifier
            let view = Button("Test") { }
                .automaticCompliance()  // ← This should set autoIDsEnabled = true
            
            // 3. Try to inspect for accessibility identifier
            // Using wrapper
            #if canImport(ViewInspector)
            if let inspectedView = try? AnyView(view).inspect(),
               let button = inspectedView.findAll(ViewInspector.ViewType.Button.self).first,
               let accessibilityID = try? button.accessibilityIdentifier() {
                print("🔍 Generated ID: '\(accessibilityID)'")

                if accessibilityID.isEmpty {
                    print("❌ FAILED: No ID generated - environment variable not working")
                    Issue.record("Environment variable not working - no ID generated")
                } else {
                    print("✅ SUCCESS: ID generated - '\(accessibilityID)'")
                }
            } else {
                print("❌ FAILED: Could not inspect view")
                Issue.record("Could not inspect view")
            }
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testDirectEnvironmentVariableSetting() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // Test: Does setting the environment variable directly work?
            
            // 1. Disable global config
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false
            print("🔧 Global config disabled: enableAutoIDs = false")
            
            // 2. Create a view with config setting (no environment variable - removed in Issue #160)
            config.globalAutomaticAccessibilityIdentifiers = true  // ← Enable via config
            let view = Button("Test") { }
                .automaticCompliance()
            
            // 3. Try to inspect for accessibility identifier
            #if canImport(ViewInspector)
            if let inspectedView = try? AnyView(view).inspect(),
               let button = inspectedView.findAll(ViewInspector.ViewType.Button.self).first,
               let accessibilityID = try? button.accessibilityIdentifier() {
                print("🔍 Generated ID: '\(accessibilityID)'")
                
                if accessibilityID.isEmpty {
                    print("❌ FAILED: No ID generated - direct environment variable not working")
                    Issue.record("Direct environment variable not working - no ID generated")
                } else {
                }
            } else {
                print("❌ FAILED: Could not inspect view")
                Issue.record("Could not inspect view")
            }
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
        }
    }
}
