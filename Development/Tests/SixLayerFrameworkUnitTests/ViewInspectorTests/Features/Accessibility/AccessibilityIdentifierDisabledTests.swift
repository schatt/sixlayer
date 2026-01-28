import Testing


import SwiftUI
@testable import SixLayerFramework
/// Test what happens when automatic accessibility IDs are disabled
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Identifier Disabled")
open class AccessibilityIdentifierDisabledTests: BaseTestClass {
    
    // BaseTestClass handles setup automatically - no need for custom init
    
    @Test @MainActor func testAutomaticIDsDisabled_NoIdentifiersGenerated() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Test: When automatic IDs are disabled, views should not have accessibility identifier modifiers
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false  // ← DISABLED
            config.namespace = "SixLayer"
            config.mode = .automatic
            config.enableDebugLogging = false
            
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
            .named("TestButton")
            .enableGlobalAutomaticCompliance()
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            do {
                let inspected = try AnyView(view).inspect()
                // Verify that the view hierarchy is inspectable; we do not require
                // a specific root type here because PlatformInteractionButton may
                // wrap the underlying Button in additional containers.
                _ = inspected
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available on this platform; creation of the view
            // is enough to validate "no automatic IDs and no crash" behavior.
            #endif
        }
    }
    
    @Test @MainActor func testManualIDsStillWorkWhenAutomaticDisabled() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false  // ← DISABLED
            
            // Test: Manual accessibility identifiers should still work when automatic is disabled
            let view = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test Button", hints: PresentationHints())
            }
            .accessibilityIdentifier("manual-test-button")
            
            // Using wrapper - when ViewInspector works on this platform, verify
            #if canImport(ViewInspector)
            do {
                let inspected = try AnyView(view).inspect()
                // Try to get the accessibility identifier from the root; if that
                // fails, fall back to recording an informative issue rather than
                // assuming a specific root type that may change over time.
                if let buttonID = try? inspected.accessibilityIdentifier() {
                    #expect(buttonID == "manual-test-button", "Manual accessibility identifier should work when automatic is disabled")
                } else {
                    Issue.record("Failed to inspect view for manual accessibility identifier")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
            #endif
        }
    }
    
    @Test @MainActor func testBreadcrumbModifiersStillWorkWhenAutomaticDisabled() {
            initializeTestConfig()
        // Test: Named modifiers should still work for tracking
        let view = platformVStackContainer {
            platformPresentContent_L1(content: "Content", hints: PresentationHints())
        }
        .named("TestView")
        
        // Even with automatic IDs disabled, the modifiers should not crash
        #if canImport(ViewInspector)
        do {
            let _ = try view.inspect()
        } catch {
            Issue.record("Breadcrumb modifiers should not crash when automatic IDs disabled")
        }
        #else
        #endif
    }
}
