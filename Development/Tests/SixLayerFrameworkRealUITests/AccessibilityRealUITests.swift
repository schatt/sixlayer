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
        config.enableDebugLogging = true  // Enable debug logging to verify modifier execution
        
        let testView = Text("Test Content")
            .automaticCompliance()
            .environment(\.globalAutomaticAccessibilityIdentifiers, true)
        
        // When: View is rendered in a real window
        let window = windowHelper!.createWindow(hosting: testView)
        await windowHelper!.waitForLayout(timeout: 0.5)
        
        // Wait for SwiftUI update cycle to ensure modifier bodies execute
        windowHelper!.waitForSwiftUIUpdates(timeout: 0.5)
        
        // Force layout pass to ensure SwiftUI updates are applied
        #if os(macOS)
        window.contentView?.layoutSubtreeIfNeeded()
        #elseif os(iOS)
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        #endif
        
        // Then: Use accessibility APIs (same as XCUITest) to find element by identifier
        // This tests that identifiers are actually usable by UI testing frameworks
        #if os(macOS)
        // Generate expected identifier using same logic as modifier
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        
        // Use NSAccessibility API to find element (same API XCUITest uses)
        let foundElement = windowHelper!.findAccessibilityElement(by: expectedIdentifier, in: window)
        #expect(foundElement != nil, "Accessibility identifier '\(expectedIdentifier)' should be findable using accessibility APIs (like XCUITest)")
        
        #elseif os(iOS)
        // Generate expected identifier using same logic as modifier
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        
        // Use UIAccessibility API to find element (same API XCUITest uses)
        let foundElement = windowHelper!.findAccessibilityElement(by: expectedIdentifier, in: window)
        #expect(foundElement != nil, "Accessibility identifier '\(expectedIdentifier)' should be findable using accessibility APIs (like XCUITest)")
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
        config.enableDebugLogging = true  // Enable debug logging to verify modifier execution
        
        let testView = Button("Test Button") {
            // Action
        }
        .automaticCompliance()
        .environment(\.globalAutomaticAccessibilityIdentifiers, true)
        
        // When: View is rendered in a real window and layout completes
        let window = windowHelper!.createWindow(hosting: testView)
        await windowHelper!.waitForLayout(timeout: 0.5)
        
        // Wait for SwiftUI update cycle to ensure modifier bodies execute
        windowHelper!.waitForSwiftUIUpdates(timeout: 0.5)
        
        // Force layout pass to ensure SwiftUI updates are applied
        #if os(macOS)
        window.contentView?.layoutSubtreeIfNeeded()
        #elseif os(iOS)
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        #endif
        
        // Then: Use accessibility APIs (same as XCUITest) to find element by identifier
        // This tests that identifiers are actually usable by UI testing frameworks
        #if os(macOS)
        // Generate expected identifier using same logic as modifier
        // Button with automaticCompliance should generate identifier with "Button" element type
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        
        // Use NSAccessibility API to find element (same API XCUITest uses)
        let foundElement = windowHelper!.findAccessibilityElement(by: expectedIdentifier, in: window)
        #expect(foundElement != nil, "Accessibility identifier '\(expectedIdentifier)' should be findable using accessibility APIs (like XCUITest)")
        
        #elseif os(iOS)
        // Generate expected identifier using same logic as modifier
        // Button with automaticCompliance should generate identifier with "Button" element type
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        
        // Use UIAccessibility API to find element (same API XCUITest uses)
        let foundElement = windowHelper!.findAccessibilityElement(by: expectedIdentifier, in: window)
        #expect(foundElement != nil, "Accessibility identifier '\(expectedIdentifier)' should be findable using accessibility APIs (like XCUITest)")
        #endif
    }
}


