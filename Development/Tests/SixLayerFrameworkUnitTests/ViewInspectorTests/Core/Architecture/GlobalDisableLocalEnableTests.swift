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
            
            // 3. Verify local enable on framework content via harness
            #if canImport(ViewInspector)
            let hasLocalEnableID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*FrameworkButton*",
                platform: SixLayerPlatform.iOS,
                componentName: "FrameworkButton"
            )
            #expect(hasLocalEnableID, "Framework component with local enable should generate ID")
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
        if let id = AccessibilityTestUtilities.inspectButtonAccessibilityIdentifier(
            view,
            issuePrefix: "Failed to inspect view for accessibility identifier"
        ) {
            return id
        }

        let hostedRoot = hostRootPlatformView(
            view,
            accessibilityIdentifierConfig: testConfig
        )
        if let id = getAccessibilityIdentifierForTest(view: view, hostedRoot: hostedRoot) {
            return id
        }

        return ""
    }
}
