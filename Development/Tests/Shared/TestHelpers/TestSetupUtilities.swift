//
//  TestSetupUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Test setup utilities for configuring platform capabilities and creating test data
//

import Foundation
import SwiftUI
@testable import SixLayerFramework

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Hosting Controller Storage

/// Thread-local storage for hosting controllers to prevent deallocation during test execution
/// Made internal for navigation view tests that need to host views directly
@MainActor
final class HostingControllerStorage {
    private static var storage: [ObjectIdentifier: Any] = [:]
    private static let lock = NSLock()
    
    static func store(_ controller: Any, for view: Any) {
        lock.lock()
        defer { lock.unlock() }
        storage[ObjectIdentifier(view as AnyObject)] = controller
    }
    
    static func remove(for view: Any) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: ObjectIdentifier(view as AnyObject))
    }
    
    static func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}

/// Test setup utilities for configuring test environments
public enum TestSetupUtilities {
    
    // MARK: - Test Hints Creation
    
    /// Create test presentation hints with default values
    public static func createTestHints(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:]
    ) -> PresentationHints {
        return PresentationHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context,
            customPreferences: customPreferences
        )
    }
    
    // MARK: - View Hosting
    
    /// Host a SwiftUI view and return the platform root view for inspection
    /// CRITICAL: The hosting controller is retained in static storage to prevent crashes
    /// when the view is accessed after the function returns.
    /// 
    /// WARNING: This function can hang if the view contains NavigationStack/NavigationView
    /// or complex hierarchies like GenericContentView in test environments without proper window hierarchy.
    /// The hang occurs when accessing `hosting.view` - a synchronous UIKit/AppKit call that cannot be timed out.
    /// - Parameters:
    ///   - view: The SwiftUI view to host.
    ///   - forceLayout: When true, call layoutIfNeeded() so SwiftUI applies accessibility identifiers to the UIView hierarchy. Use only for simple views (e.g. Text, Button); complex views (NavigationStack, platformPresentContent_L1) can hang.
    @MainActor
    public static func hostRootPlatformView<V: View>(_ view: V, forceLayout: Bool = false) -> Any? {
        #if canImport(UIKit)
        let hosting = UIHostingController(rootView: view)
        // CRITICAL: Accessing hosting.view can hang on complex views in test environments.
        // This is a synchronous UIKit call that cannot be timed out or cancelled.
        // If this hangs, the test will hang indefinitely.
        let root = hosting.view
        // Add hosting view to a window so SwiftUI propagates accessibilityIdentifier to the UIView hierarchy.
        // Without a window, identifiers may not be set on platform views (iOS behavior).
        if let root = root {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
            window.rootViewController = hosting
            window.makeKeyAndVisible()
            // Allow one run loop so UIKit/SwiftUI can apply accessibility traits to the hierarchy
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            // Optionally force layout so identifiers are applied to the UIView tree (Option A for a11y tests).
            // Only use for simple views; complex views can hang (NavigationStack, platformPresentContent_L1).
            if forceLayout {
                root.setNeedsLayout()
                root.layoutIfNeeded()
            }
            // Store both so window and controller stay alive; keyed by root for cleanup
            HostingControllerStorage.store((controller: hosting, window: window), for: root)
        }
        
        // Force accessibility update (doesn't require layout)
        root?.accessibilityElementsHidden = false
        root?.isAccessibilityElement = true
        
        return root
        #elseif canImport(AppKit)
        let hosting = NSHostingController(rootView: view)
        // CRITICAL: Accessing hosting.view can hang on complex views in test environments.
        let root = hosting.view
        // CRITICAL: Store the hosting controller to prevent deallocation
        HostingControllerStorage.store(hosting, for: root)
        if forceLayout {
            root.needsLayout = true
            root.layoutSubtreeIfNeeded()
        }
        root.setAccessibilityElement(true)
        return root
        #else
        return nil
        #endif
    }
    
    // MARK: - Field Type Helpers
    
    /// Field type enum for test utilities
    public enum FieldType {
        case text
        case email
        case number
        case phone
        case date
        case url
        case textarea
        case select
        case multiselect
        case radio
        case checkbox
        case richtext
    }
    
    /// Convert FieldType to DynamicContentType
    public static func contentType(for fieldType: FieldType) -> DynamicContentType {
        switch fieldType {
        case .text:
            return .text
        case .email:
            return .email
        case .number:
            return .number
        case .phone:
            return .phone
        case .date:
            return .date
        case .url:
            return .url
        case .textarea:
            return .textarea
        case .select:
            return .select
        case .multiselect:
            return .multiselect
        case .radio:
            return .radio
        case .checkbox:
            return .checkbox
        case .richtext:
            return .richtext
        }
    }
    
    // MARK: - Test Field Creation
    
    /// Create a test form field with the specified parameters
    public static func createTestField(
        label: String,
        placeholder: String? = nil,
        value: String? = nil,
        isRequired: Bool = false,
        contentType: DynamicContentType,
        options: [String]? = nil
    ) -> DynamicFormField {
        let fieldId = label.lowercased().replacingOccurrences(of: " ", with: "_")
        return DynamicFormField(
            id: fieldId,
            contentType: contentType,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            options: options,
            defaultValue: value
        )
    }
    
    // MARK: - Test Environment Setup
    
    /// Setup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func setupTestEnvironment() {
        // Clear any existing test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Additional setup can be added here as needed
    }
    
    /// Cleanup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func cleanupTestEnvironment() {
        // Clear all test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Additional cleanup can be added here as needed
    }
}
