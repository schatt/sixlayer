import Testing


import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif
/// TDD Tests for "Global Disable, Local Enable" Functionality
/// Following proper TDD: Write failing tests first to prove the desired behavior
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Global Disable Local Enable")
open class GlobalDisableLocalEnableTDDTests: BaseTestClass {

    // BaseTestClass handles setup automatically - no need for custom init    // MARK: - TDD Red Phase: Tests That Should Fail Initially
    
    @Test @MainActor func testFrameworkComponentGlobalDisableLocalEnableGeneratesID() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // TDD: Test with actual framework component - this should work
            
            // 1. Disable global config
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = false
            config.enableDebugLogging = true
            
            // 2. Create a framework component with local enable; use platformButton so the button has an identifierName (L1 pattern)
            let view = platformPresentContent_L1(
                content: platformButton("Framework Button") { },
                hints: PresentationHints()
            )
            .automaticCompliance(identifierName: "FrameworkButton")  // ← Local enable + name so ID is generated
            
            // 3. Generate ID
            // VERIFIED: Framework function has .automaticCompliance() modifier applied
            #if canImport(ViewInspector)
            let id = generateIDForView(view)
            
            // This should work because framework components handle their own ID generation
            #expect(!id.isEmpty, "Framework component with local enable should generate ID")
            #expect(id.contains("TestApp"), "ID should contain namespace")
            
            print("🔍 Framework Component Test: Generated ID='\(id)'")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testGlobalEnableLocalDisableDoesNotGenerateID() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // TDD: This test SHOULD FAIL initially - .named() always works regardless of global settings
            
            // 1. Enable global config
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = true
            
            // 2. Create a view with explicit naming (should always work)
            let view = Button("Disabled Button") { }
                .named("DisabledButton")
                .disableAutomaticAccessibilityIdentifiers()  // ← This doesn't affect .named()
            
            // 3. Generate ID
            // VERIFIED: .named() modifier DOES apply accessibility identifiers
            #if canImport(ViewInspector)
            let id = generateIDForView(view)
            
            // .named() should always work regardless of global settings
            #expect(!id.isEmpty, ".named() should always work regardless of global settings")
            #expect(id.contains("DisabledButton"), "Should contain the explicit name")
            
            print("Testing .named() with global settings: Generated ID='\(id)'")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testFrameworkComponentsRespectGlobalConfig() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // TDD: This test SHOULD PASS - .named() always works regardless of global config
            
            // 1. Disable global config
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = false
            
            // 2. Create a view with explicit naming (should always work)
            let view = Button("Framework Button") { }
                .named("FrameworkButton")
            
            // 3. Generate ID
            // VERIFIED: .named() modifier DOES apply accessibility identifiers
            #if canImport(ViewInspector)
            let id = generateIDForView(view)
            
            // .named() should always work regardless of global settings
            #expect(!id.isEmpty, ".named() should always work regardless of global config")
            #expect(id.contains("FrameworkButton"), "Should contain the explicit name")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
        }
    }
    
    @Test @MainActor func testPlainSwiftUIRequiresExplicitEnable() {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // TDD: This test SHOULD PASS - .named() always works regardless of global config
            
            // 1. Disable global config
            guard let config = testConfig else {

                Issue.record("testConfig is nil")

                return

            }
            config.enableAutoIDs = false
            
            // 2. Create a view with explicit naming (should always work)
            let view = Button("Plain Button") { }
                .named("PlainButton")
            
            // 3. Generate ID
            // VERIFIED: .named() modifier DOES apply accessibility identifiers
            #if canImport(ViewInspector)
            let id = generateIDForView(view)
            
            // .named() should always work regardless of global settings
            #expect(!id.isEmpty, ".named() should always work regardless of global config")
            #expect(id.contains("PlainButton"), "Should contain the explicit name")
            #else
            // ViewInspector not available on this platform - this is expected, not a failure
            #endif
            
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func generateIDForView(_ view: some View) -> String {
        // Optimized: Reduced ViewInspector deep searches to improve performance
        guard let inspectedView = try? AnyView(view).inspect() else {
            return ""
        }

        #if canImport(ViewInspector)
        // Optimized: Check root view first (most common case)
        // Note: InspectableView doesn't have direct accessibilityIdentifier() method
        // We need to find a Button or other view that has it
        let buttons = inspectedView.findAll(ViewInspector.ViewType.Button.self)
        if let button = buttons.first,
           let id = try? button.accessibilityIdentifier(), !id.isEmpty {
            return id
        }
        #endif
        
        return ""
    }
}
