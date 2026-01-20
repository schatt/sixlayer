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
    
    /// Manually transfer accessibility identifiers from SwiftUI to AppKit views
    /// SwiftUI's .accessibilityIdentifier() doesn't always propagate to AppKit in test environments.
    /// This method manually sets the identifier on the AppKit view hierarchy using the same
    /// generation logic as the modifier, ensuring identifiers are accessible for UI testing.
    /// - Parameter window: The window containing the SwiftUI view
    public func transferAccessibilityIdentifiers(to window: NSWindow) {
        guard let viewController = window.contentViewController,
              let rootView = viewController.view else {
            return
        }
        
        // Get the config to generate the same identifier
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        
        // Generate identifier using the same logic as the modifier
        let namespace = config.namespace.isEmpty ? nil : config.namespace
        let screenContext = config.enableUITestIntegration ? "main" : (config.currentScreenContext ?? "main")
        let viewHierarchyPath = config.enableUITestIntegration ? "ui" : (config.currentViewHierarchy.isEmpty ? "ui" : config.currentViewHierarchy.joined(separator: "."))
        let componentName = config.includeComponentNames ? "element" : nil
        let elementType = config.includeElementTypes ? "View" : nil
        
        var identifierComponents: [String] = []
        if let namespace = namespace {
            identifierComponents.append(namespace)
        }
        identifierComponents.append(screenContext)
        identifierComponents.append(viewHierarchyPath)
        if let componentName = componentName {
            identifierComponents.append(componentName)
        }
        if let elementType = elementType {
            identifierComponents.append(elementType)
        }
        
        let identifier = identifierComponents.joined(separator: ".")
        
        // Find and set identifier on NSHostingView instances (SwiftUI's internal view type)
        func setIdentifierOnHostingViews(in view: NSView, identifier: String) {
            // Check if this is an NSHostingView (SwiftUI's internal view type)
            let viewType = String(describing: type(of: view))
            if viewType.contains("HostingView") || viewType.contains("NSHostingView") {
                view.setAccessibilityIdentifier(identifier)
            }
            // Recursively check subviews
            for subview in view.subviews {
                setIdentifierOnHostingViews(in: subview, identifier: identifier)
            }
        }
        
        setIdentifierOnHostingViews(in: rootView, identifier: identifier)
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
    
    /// Manually transfer accessibility identifiers from SwiftUI to UIKit views
    /// SwiftUI's .accessibilityIdentifier() doesn't always propagate to UIKit in test environments.
    /// This method manually sets the identifier on the UIKit view hierarchy using the same
    /// generation logic as the modifier, ensuring identifiers are accessible for UI testing.
    /// - Parameter window: The window containing the SwiftUI view
    public func transferAccessibilityIdentifiers(to window: UIWindow) {
        guard let viewController = window.rootViewController,
              let rootView = viewController.view else {
            return
        }
        
        // Get the config to generate the same identifier
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        
        // Generate identifier using the same logic as the modifier
        let namespace = config.namespace.isEmpty ? nil : config.namespace
        let screenContext = config.enableUITestIntegration ? "main" : (config.currentScreenContext ?? "main")
        let viewHierarchyPath = config.enableUITestIntegration ? "ui" : (config.currentViewHierarchy.isEmpty ? "ui" : config.currentViewHierarchy.joined(separator: "."))
        let componentName = config.includeComponentNames ? "element" : nil
        let elementType = config.includeElementTypes ? "View" : nil
        
        var identifierComponents: [String] = []
        if let namespace = namespace {
            identifierComponents.append(namespace)
        }
        identifierComponents.append(screenContext)
        identifierComponents.append(viewHierarchyPath)
        if let componentName = componentName {
            identifierComponents.append(componentName)
        }
        if let elementType = elementType {
            identifierComponents.append(elementType)
        }
        
        let identifier = identifierComponents.joined(separator: ".")
        
        // Find and set identifier on UIHostingView instances (SwiftUI's internal view type)
        func setIdentifierOnHostingViews(in view: UIView, identifier: String) {
            // Check if this is a UIHostingView (SwiftUI's internal view type)
            let viewType = String(describing: type(of: view))
            if viewType.contains("HostingView") || viewType.contains("UIHostingView") {
                view.accessibilityIdentifier = identifier
            }
            // Recursively check subviews
            for subview in view.subviews {
                setIdentifierOnHostingViews(in: subview, identifier: identifier)
            }
        }
        
        setIdentifierOnHostingViews(in: rootView, identifier: identifier)
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

