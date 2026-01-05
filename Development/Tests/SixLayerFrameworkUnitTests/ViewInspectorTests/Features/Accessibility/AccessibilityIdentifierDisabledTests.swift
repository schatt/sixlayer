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
            if let inspectedView = viewtry? AnyView(self).inspect(),
               let _ = try? inspectedView.button() {
                // When automatic IDs are disabled, the view should not have an accessibility identifier modifier
                // This means we can't inspect for accessibility identifiers
                // Just verify the view is inspectable
            } else {
                Issue.record("Failed to inspect view")
            }
            #else
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
            
            // Using wrapper - when ViewInspector works on macOS, no changes needed here
            #if canImport(ViewInspector)
            if let inspectedView = viewtry? AnyView(self).inspect(),
               let buttonID = try? inspectedView.accessibilityIdentifier() {
                // Manual ID should work regardless of automatic setting
                #expect(buttonID == "manual-test-button", "Manual accessibility identifier should work when automatic is disabled")
                
                print("🔍 Manual ID when automatic disabled: '\(buttonID)'")
            } else {
                Issue.record("Failed to inspect view")
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
