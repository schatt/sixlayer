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
        await windowHelper!.waitForLayout(timeout: 0.5)
        
        // Force layout pass to ensure SwiftUI updates are applied
        #if os(macOS)
        window.contentView?.layoutSubtreeIfNeeded()
        #elseif os(iOS)
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        #endif
        
        // Then: Accessibility identifier should be accessible through platform APIs
        #if os(macOS)
        // Cast to base NSViewController since the view may be wrapped by modifiers
        // The hosting controller's generic type is not Text after modifiers are applied
        guard let viewController = window.contentViewController else {
            #expect(Bool(false), "Window should have a content view controller")
            return
        }
        let rootView = viewController.view
        
        // Search the view hierarchy for the accessibility identifier
        // SwiftUI may apply the identifier to a nested view, not the root
        func findAccessibilityIdentifier(in view: NSView) -> String? {
            // Check this view
            let id = view.accessibilityIdentifier()
            if let id = id, !id.isEmpty {
                return id
            }
            // Recursively check subviews
            for subview in view.subviews {
                if let id = findAccessibilityIdentifier(in: subview) {
                    return id
                }
            }
            return nil
        }
        
        let accessibilityID = findAccessibilityIdentifier(in: rootView)
        #expect(accessibilityID != nil, "Accessibility identifier should be generated in real window")
        #expect(!accessibilityID!.isEmpty, "Accessibility identifier should not be empty")
        
        #elseif os(iOS)
        // Cast to base UIViewController since the view may be wrapped by modifiers
        // The hosting controller's generic type is not Text after modifiers are applied
        guard let viewController = window.rootViewController else {
            #expect(Bool(false), "Window should have a root view controller")
            return
        }
        let rootView = viewController.view!
        
        // Search the view hierarchy for the accessibility identifier
        // SwiftUI may apply the identifier to a nested view, not the root
        func findAccessibilityIdentifier(in view: UIView) -> String? {
            // Check this view
            if let id = view.accessibilityIdentifier, !id.isEmpty {
                return id
            }
            // Recursively check subviews
            for subview in view.subviews {
                if let id = findAccessibilityIdentifier(in: subview) {
                    return id
                }
            }
            return nil
        }
        
        let accessibilityID = findAccessibilityIdentifier(in: rootView)
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
        await windowHelper!.waitForLayout(timeout: 0.5)
        
        // Force layout pass to ensure SwiftUI updates are applied
        #if os(macOS)
        window.contentView?.layoutSubtreeIfNeeded()
        #elseif os(iOS)
        window.rootViewController?.view.setNeedsLayout()
        window.rootViewController?.view.layoutIfNeeded()
        #endif
        
        // Then: Modifier body should have executed (identifier should be present)
        #if os(macOS)
        // Cast to base NSViewController since the view may be wrapped by modifiers
        guard let viewController = window.contentViewController else {
            #expect(Bool(false), "Window should have a content view controller")
            return
        }
        let rootView = viewController.view
        
        // Search the view hierarchy for the accessibility identifier
        func findAccessibilityIdentifier(in view: NSView) -> String? {
            let id = view.accessibilityIdentifier()
            if let id = id, !id.isEmpty {
                return id
            }
            for subview in view.subviews {
                if let id = findAccessibilityIdentifier(in: subview) {
                    return id
                }
            }
            return nil
        }
        
        let accessibilityID = findAccessibilityIdentifier(in: rootView)
        #expect(accessibilityID != nil && !accessibilityID!.isEmpty, "Modifier body should execute in real window")
        
        #elseif os(iOS)
        // Cast to base UIViewController since the view may be wrapped by modifiers
        guard let viewController = window.rootViewController else {
            #expect(Bool(false), "Window should have a root view controller")
            return
        }
        let rootView = viewController.view!
        
        // Search the view hierarchy for the accessibility identifier
        func findAccessibilityIdentifier(in view: UIView) -> String? {
            if let id = view.accessibilityIdentifier, !id.isEmpty {
                return id
            }
            for subview in view.subviews {
                if let id = findAccessibilityIdentifier(in: subview) {
                    return id
                }
            }
            return nil
        }
        
        let accessibilityID = findAccessibilityIdentifier(in: rootView)
        #expect(accessibilityID != nil && !accessibilityID!.isEmpty, "Modifier body should execute in real window")
        #endif
    }
}


