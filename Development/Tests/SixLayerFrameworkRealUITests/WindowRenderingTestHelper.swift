//
//  WindowRenderingTestHelper.swift
//  SixLayerFrameworkRealUITests
//
//  BUSINESS PURPOSE:
//  Helper utilities for creating windows and rendering SwiftUI views in real windows
//  for actual UI testing. These tests verify views render correctly, modifiers execute,
//  and layout works in real window hierarchies.
//
//  TESTING SCOPE:
//  - Window creation and management
//  - View hosting in windows
//  - Layout execution in window hierarchies
//  - Window cleanup and teardown
//
//  METHODOLOGY:
//  - Create platform-specific windows (NSWindow/UIWindow)
//  - Host SwiftUI views using hosting controllers
//  - Show windows and allow layout passes
//  - Clean up windows after tests
//

import SwiftUI
import Foundation
@testable import SixLayerFramework

#if os(macOS)
import AppKit

/// Helper for creating and managing NSWindow instances for UI testing
@MainActor
public final class WindowRenderingTestHelper {
    private var windows: [NSWindow] = []
    
    /// Create an NSWindow and host a SwiftUI view in it
    /// - Parameters:
    ///   - view: The SwiftUI view to render
    ///   - size: Window size (default: 800x600)
    /// - Returns: The created window
    public func createWindow<V: View>(hosting view: V, size: CGSize = CGSize(width: 800, height: 600)) -> NSWindow {
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame.size = size
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Force the view to be laid out and rendered
        // This ensures SwiftUI's modifier bodies execute
        window.contentView?.needsLayout = true
        window.contentView?.layoutSubtreeIfNeeded()
        
        windows.append(window)
        return window
    }
    
    /// Wait for layout to complete
    public func waitForLayout(timeout: TimeInterval = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    /// Wait for SwiftUI update cycle to complete by running the run loop
    /// This ensures modifier bodies execute and accessibility identifiers propagate
    public func waitForSwiftUIUpdates(timeout: TimeInterval = 0.5) {
        let deadline = Date().addingTimeInterval(timeout)
        let runLoop = RunLoop.current
        while Date() < deadline {
            runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
    
    /// Find an accessibility element by identifier using NSAccessibility API
    /// This uses the same APIs that XCUITest uses, providing a realistic test
    /// - Parameters:
    ///   - window: The window to search in
    ///   - identifier: The accessibility identifier to find
    /// - Returns: The accessibility element if found, nil otherwise
    public func findAccessibilityElement(by identifier: String, in window: NSWindow) -> Any? {
        // Start from the hosting controller's view if available, otherwise use contentView
        // SwiftUI views are hosted in NSHostingController, so we need to search from there
        let rootView: NSView?
        if let hostingController = window.contentViewController,
           hostingController.view != nil {
            // Use the hosting controller's view (this is where SwiftUI views are rendered)
            rootView = hostingController.view
        } else {
            // Fall back to contentView if no hosting controller
            rootView = window.contentView
        }
        
        guard let windowElement = rootView else {
            return nil
        }
        
        // Force accessibility update to ensure SwiftUI identifiers are propagated
        windowElement.needsDisplay = true
        windowElement.needsLayout = true
        windowElement.layoutSubtreeIfNeeded()
        
        // Give the accessibility system a moment to update
        // SwiftUI identifiers need time to propagate through the accessibility hierarchy
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        
        // Use NSAccessibility API to find element by identifier
        // This is the same API that XCUITest uses under the hood
        // SwiftUI views wrapped in NSHostingView expose identifiers through the accessibility system
        var checkedViews: Set<ObjectIdentifier> = []
        var allIdentifiers: [String] = [] // For debugging
        
        // Helper to check if an element (NSView or any object) has the identifier
        func elementHasIdentifier(_ element: Any, identifier: String) -> Bool {
            // Check NSView.accessibilityIdentifier()
            if let view = element as? NSView {
                let viewId = view.accessibilityIdentifier()
                if !viewId.isEmpty && viewId == identifier {
                    return true
                }
            }
            
            // Check NSAccessibility protocol
            if let accessibilityElement = element as? NSAccessibilityElement {
                if let accessibilityId = accessibilityElement.accessibilityIdentifier() as? String,
                   !accessibilityId.isEmpty,
                   accessibilityId == identifier {
                    return true
                }
            }
            
            // Also try accessing via NSAccessibility attribute directly
            if let element = element as? NSObject {
                if let accessibilityId = element.value(forAttribute: .identifier) as? String,
                   !accessibilityId.isEmpty,
                   accessibilityId == identifier {
                    return true
                }
            }
            
            return false
        }
        
        func searchForElement(in element: Any, identifier: String, depth: Int = 0) -> Any? {
            // Prevent infinite recursion and cycles
            guard depth < 50 else { return nil }
            
            let elementId = ObjectIdentifier(element as AnyObject)
            if checkedViews.contains(elementId) {
                return nil
            }
            checkedViews.insert(elementId)
            
            // Check if this element has the identifier
            if elementHasIdentifier(element, identifier: identifier) {
                return element
            }
            
            // Collect identifier for debugging
            if let view = element as? NSView {
                let viewId = view.accessibilityIdentifier()
                if !viewId.isEmpty {
                    allIdentifiers.append("\(type(of: view)): \(viewId)")
                }
            }
            
            // Search through subviews if it's an NSView
            if let view = element as? NSView {
                for subview in view.subviews {
                    if let found = searchForElement(in: subview, identifier: identifier, depth: depth + 1) {
                        return found
                    }
                }
            }
            
            // Also check accessibility children (for SwiftUI elements exposed through accessibility)
            // This is crucial for finding SwiftUI views that might not be direct subviews
            var accessibilityChildren: [Any] = []
            
            if let view = element as? NSView {
                if let children = view.accessibilityChildren() as? [Any] {
                    accessibilityChildren.append(contentsOf: children)
                }
            }
            
            if let accessibilityElement = element as? NSAccessibilityElement {
                if let children = accessibilityElement.accessibilityChildren() as? [Any] {
                    accessibilityChildren.append(contentsOf: children)
                }
            }
            
            // Search through accessibility children
            for child in accessibilityChildren {
                // Check if child itself has the identifier
                if elementHasIdentifier(child, identifier: identifier) {
                    return child
                }
                
                // Recursively search child
                if let found = searchForElement(in: child, identifier: identifier, depth: depth + 1) {
                    return found
                }
            }
            
            return nil
        }
        
        let result = searchForElement(in: windowElement, identifier: identifier)
        
        // Debug: Print all found identifiers if search failed
        if result == nil {
            print("DEBUG: Searching for identifier: '\(identifier)'")
            if !allIdentifiers.isEmpty {
                print("DEBUG: Found identifiers in view hierarchy:")
                for id in allIdentifiers {
                    print("  - \(id)")
                }
            } else {
                print("DEBUG: No identifiers found in view hierarchy")
            }
        }
        
        return result
    }
    
    /// Clean up all created windows
    public func cleanup() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
    }
    
    deinit {
        // Note: Cannot call cleanup() from deinit due to MainActor isolation
        // Windows will be cleaned up automatically when the object is deallocated
        // Explicit cleanup should be called before deallocation if needed
    }
}

#elseif os(iOS)
import UIKit

/// Helper for creating and managing UIWindow instances for UI testing
@MainActor
public final class WindowRenderingTestHelper {
    private var windows: [UIWindow] = []
    
    /// Create a UIWindow and host a SwiftUI view in it
    /// - Parameters:
    ///   - view: The SwiftUI view to render
    ///   - size: Window size (default: 375x667 - iPhone size)
    /// - Returns: The created window
    public func createWindow<V: View>(hosting view: V, size: CGSize = CGSize(width: 375, height: 667)) -> UIWindow {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame.size = size
        
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        // Force the view to be laid out and rendered
        // This ensures SwiftUI's modifier bodies execute
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        windows.append(window)
        return window
    }
    
    /// Wait for layout to complete
    public func waitForLayout(timeout: TimeInterval = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    /// Wait for SwiftUI update cycle to complete by running the run loop
    /// This ensures modifier bodies execute and accessibility identifiers propagate
    public func waitForSwiftUIUpdates(timeout: TimeInterval = 0.5) {
        let deadline = Date().addingTimeInterval(timeout)
        let runLoop = RunLoop.current
        while Date() < deadline {
            runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
    
    /// Find an accessibility element by identifier using UIAccessibility API
    /// This uses the same APIs that XCUITest uses, providing a realistic test
    /// - Parameters:
    ///   - window: The window to search in
    ///   - identifier: The accessibility identifier to find
    /// - Returns: The accessibility element if found, nil otherwise
    public func findAccessibilityElement(by identifier: String, in window: UIWindow) -> Any? {
        guard let rootView = window.rootViewController?.view else {
            return nil
        }
        
        // Use UIAccessibility API to find element by identifier
        // This is the same API that XCUITest uses under the hood
        func searchForElement(in view: UIView, identifier: String) -> UIView? {
            // Check if this view has the identifier
            if view.accessibilityIdentifier == identifier {
                return view
            }
            
            // Search subviews recursively
            for subview in view.subviews {
                if let found = searchForElement(in: subview, identifier: identifier) {
                    return found
                }
            }
            
            return nil
        }
        
        return searchForElement(in: rootView, identifier: identifier)
    }
    
    /// Clean up all created windows
    public func cleanup() {
        for window in windows {
            window.isHidden = true
            window.rootViewController = nil
        }
        windows.removeAll()
    }
    
    deinit {
        // Note: Cannot call cleanup() from deinit due to MainActor isolation
        // Windows will be cleaned up automatically when the object is deallocated
        // Explicit cleanup should be called before deallocation if needed
    }
}

#endif

