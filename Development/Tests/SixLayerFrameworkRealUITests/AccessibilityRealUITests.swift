//
//  AccessibilityRealUITests.swift
//  SixLayerFrameworkRealUITests
//
//  BUSINESS PURPOSE:
//  Real UI tests that verify accessibility identifiers are actually generated
//  and accessible when views are rendered in real windows. These tests verify
//  that modifier bodies execute, layout happens, and accessibility features
//  work in actual window hierarchies.
//
//  TESTING SCOPE:
//  - Actual accessibility identifier generation in real windows
//  - Modifier body execution (EnvironmentAccessor.body) in window hierarchies
//  - Layout calculations that only happen in windows
//  - Accessibility API access to rendered views
//
//  METHODOLOGY:
//  - Create real windows (NSWindow/UIWindow)
//  - Render views in windows
//  - Wait for layout to complete
//  - Access accessibility identifiers through platform APIs
//  - Verify identifiers are present and correct
//

import Testing
import SwiftUI
@testable import SixLayerFramework

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Real UI tests for accessibility identifier generation
/// These tests render views in actual windows to verify full rendering pipeline
@Suite("Accessibility Real UI Tests")
final class AccessibilityRealUITests {
    private var windowHelper: WindowRenderingTestHelper?
    
    @MainActor
    func setUp() {
        windowHelper = WindowRenderingTestHelper()
    }
    
    @MainActor
    func tearDown() {
        windowHelper?.cleanup()
        windowHelper = nil
    }
    
    /// Test that accessibility identifiers are generated when view is rendered in a real window
    @Test @MainActor
    func testAccessibilityIdentifiersGeneratedInRealWindow() async throws {
        setUp()
        defer { tearDown() }
        
        // Given: A view with automatic compliance
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        
        let testView = Text("Test Content")
            .automaticCompliance()
            .environment(\.globalAutomaticAccessibilityIdentifiers, true)
        
        // When: View is rendered in a real window
        let window = windowHelper!.createWindow(hosting: testView)
        await windowHelper!.waitForLayout(timeout: 0.2)
        
        // Then: Accessibility identifier should be accessible through platform APIs
        #if os(macOS)
        let hostingController = window.contentViewController as! NSHostingController<Text>
        let platformView = hostingController.view
        
        // Access accessibility identifier through AppKit
        let accessibilityID = platformView.accessibilityIdentifier()
        #expect(accessibilityID != nil, "Accessibility identifier should be generated in real window")
        #expect(!accessibilityID.isEmpty, "Accessibility identifier should not be empty")
        
        #elseif os(iOS)
        let hostingController = window.rootViewController as! UIHostingController<Text>
        let platformView = hostingController.view!
        
        // Access accessibility identifier through UIKit
        let accessibilityID = platformView.accessibilityIdentifier
        #expect(accessibilityID != nil, "Accessibility identifier should be generated in real window")
        #expect(!accessibilityID!.isEmpty, "Accessibility identifier should not be empty")
        #endif
    }
    
    /// Test that modifier body executes when view is in a real window
    @Test @MainActor
    func testModifierBodyExecutesInRealWindow() async throws {
        setUp()
        defer { tearDown() }
        
        // Given: A view with automatic compliance
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        
        let testView = Button("Test Button") {
            // Action
        }
        .automaticCompliance()
        .environment(\.globalAutomaticAccessibilityIdentifiers, true)
        
        // When: View is rendered in a real window and layout completes
        let window = windowHelper!.createWindow(hosting: testView)
        await windowHelper!.waitForLayout(timeout: 0.2)
        
        // Then: Modifier body should have executed (identifier should be present)
        #if os(macOS)
        let hostingController = window.contentViewController as! NSHostingController<Button<Text>>
        let platformView = hostingController.view
        let accessibilityID = platformView.accessibilityIdentifier()
        #expect(accessibilityID != nil && !accessibilityID.isEmpty, "Modifier body should execute in real window")
        
        #elseif os(iOS)
        let hostingController = window.rootViewController as! UIHostingController<Button<Text>>
        let platformView = hostingController.view!
        let accessibilityID = platformView.accessibilityIdentifier
        #expect(accessibilityID != nil && !accessibilityID!.isEmpty, "Modifier body should execute in real window")
        #endif
    }
}


