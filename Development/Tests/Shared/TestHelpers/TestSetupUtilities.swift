//
//  TestSetupUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Test setup utilities for configuring platform capabilities and creating test data
//

import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Hosting Controller Storage

/// Per-test-invocation retention for hosted UIKit/AppKit windows.
///
/// Parallel-safe: each test's `HostedViewTestIsolationTrait` installs a dedicated session in
/// `@TaskLocal`. No global map, lock, or cross-test slot.
final class HostingSession: @unchecked Sendable {
    private struct HostedEntry {
        let window: AnyObject
        let controller: AnyObject

        @MainActor
        func tearDown() {
            #if canImport(UIKit) && !os(watchOS)
            if let hosting = controller as? UIHostingController<AnyView> {
                hosting.rootView = AnyView(EmptyView())
            }
            if let window = window as? UIWindow {
                window.isHidden = true
                window.rootViewController = nil
            }
            #endif
            #if canImport(AppKit)
            if let hosting = controller as? NSHostingController<AnyView> {
                hosting.rootView = AnyView(EmptyView())
            }
            if let window = window as? NSWindow {
                window.orderOut(nil)
                window.contentViewController = nil
            }
            #endif
        }
    }

    private var entries: [ObjectIdentifier: HostedEntry] = [:]

    @MainActor
    func store(controller: AnyObject, window: AnyObject, for view: Any) {
        let key = ObjectIdentifier(view as AnyObject)
        entries[key] = HostedEntry(window: window, controller: controller)
    }

    @MainActor
    func tearDownAll() {
        for entry in entries.values {
            entry.tearDown()
        }
        entries.removeAll()
    }
}

enum HostingControllerStorage {
    /// Active per-test session; set by `HostedViewTestIsolationTrait` on the test task.
    @TaskLocal static var session: HostingSession?
    /// Active test id; set by isolation traits for attribution.
    @TaskLocal static var scopeTestID: Test.ID?

    @MainActor
    static func store(controller: AnyObject, window: AnyObject, for view: Any) {
        guard let session = HostingControllerStorage.session else {
            Issue.record(
                "hostRootPlatformView requires HostedViewTestIsolationTrait on the enclosing @Suite"
            )
            return
        }
        session.store(controller: controller, window: window, for: view)
    }

    @MainActor
    static func tearDownActiveSession() {
        session?.tearDownAll()
    }
}

@MainActor
private func pumpHostedViewRunLoop(for duration: TimeInterval) {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
        RunLoop.main.run(mode: .common, before: Date(timeIntervalSinceNow: 0.005))
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
    ///   - exposeContentAccessibility: When true, leave the hosting root as a container (isAccessibilityElement = false) so the SwiftUI content's accessibility tree is exposed for verification (e.g. single tappable element with label + button trait). Use for tests that traverse the hierarchy to assert on content a11y (Issue #191).
    ///   - accessibilityIdentifierConfig: When set, rebinds `@TaskLocal` around hosting and layout so identifier modifiers see this instance (`resolvedForIdentifierGeneration`). When nil, uses the current task-local config if any. Does not inject SwiftUI Environment (#435).
    @MainActor
    public static func hostRootPlatformView<V: View>(
        _ view: V,
        forceLayout: Bool = false,
        exposeContentAccessibility: Bool = false,
        accessibilityIdentifierConfig: AccessibilityIdentifierConfig? = nil
    ) -> Any? {
        autoreleasepool {
        let injectedConfig = accessibilityIdentifierConfig ?? AccessibilityIdentifierConfig.currentTaskLocalConfig
        #if canImport(UIKit) && !os(watchOS)
        // Re-bind task-local config for the whole hosting + layout window so SwiftUI modifier bodies that run
        // synchronously during layout still see the isolated test config (and debug log), not only `.shared`.
        let hostUIKitSubtree: () -> UIView? = {
            let hosting = UIHostingController(rootView: view)
            // CRITICAL: Accessing hosting.view can hang on complex views in test environments.
            // This is a synchronous UIKit call that cannot be timed out or cancelled.
            // If this hangs, the test will hang indefinitely.
            let root = hosting.view
            // Add hosting view to a window so SwiftUI propagates accessibilityIdentifier to the UIView hierarchy.
            // Without a window, identifiers may not be set on platform views (iOS behavior).
            if let root = root {
                let window = UIWindow(frame: CGRect(x: -10_000, y: -10_000, width: 400, height: 400))
                window.rootViewController = hosting
                window.makeKeyAndVisible()
                // Drive appearance so SwiftUI/UIKit commit the view hierarchy (identifiers often stay empty without this in unit tests).
                hosting.beginAppearanceTransition(true, animated: false)
                hosting.endAppearanceTransition()
                pumpHostedViewRunLoop(for: 0.1)
                // Optionally force layout so identifiers are applied to the UIView tree (Option A for a11y tests).
                // Only use for simple views; complex views can hang (NavigationStack, platformPresentContent_L1).
                if forceLayout {
                    root.setNeedsLayout()
                    root.layoutIfNeeded()
                    pumpHostedViewRunLoop(for: 0.02)
                    root.setNeedsLayout()
                    root.layoutIfNeeded()
                }
                // Store both so window and controller stay alive; keyed by root for cleanup
                HostingControllerStorage.store(controller: hosting, window: window, for: root)
                pumpHostedViewRunLoop(for: 0.15)
            }
            return root
        }
        let root: UIView?
        if let cfg = injectedConfig {
            root = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(cfg) {
                hostUIKitSubtree()
            }
        } else {
            root = hostUIKitSubtree()
        }
        // When exposeContentAccessibility is true, keep root as a container so content's a11y (e.g. combined card element) is visible to traversal. Otherwise mark root as element for other tests.
        root?.accessibilityElementsHidden = false
        root?.isAccessibilityElement = !exposeContentAccessibility
        
        return root
        #elseif canImport(AppKit)
        // Mirror UIKit hosting: without a visible window + run loop, SwiftUI on macOS often never
        // evaluates modifier bodies, so automaticCompliance / debug logs stay empty (Layer 4 a11y tests).
        let hostAppKitSubtree: () -> NSView? = {
            let hosting = NSHostingController(rootView: view)
            let frame = NSRect(x: -10_000, y: -10_000, width: 480, height: 640)
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: true
            )
            window.isReleasedWhenClosed = false
            window.contentViewController = hosting
            window.setFrame(frame, display: false)
            window.orderOut(nil)
            let root = hosting.view
            // Retain window + controller like UIKit path so layout and a11y stay alive for traversal.
            HostingControllerStorage.store(controller: hosting, window: window, for: root)
            pumpHostedViewRunLoop(for: 0.12)
            if forceLayout {
                root.needsLayout = true
                root.layoutSubtreeIfNeeded()
                pumpHostedViewRunLoop(for: 0.05)
            }
            pumpHostedViewRunLoop(for: 0.15)
            root.setAccessibilityElement(!exposeContentAccessibility)
            return root
        }
        let root: NSView?
        if let cfg = injectedConfig {
            root = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(cfg) {
                hostAppKitSubtree()
            }
        } else {
            root = hostAppKitSubtree()
        }
        return root
        #else
        return nil
        #endif
        }
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
    
    /// Creates a fresh `AccessibilityIdentifierConfig` for unit tests.
    ///
    /// **Parallel safety:** Uses a unique `UserDefaults` suite per call so parallel tests do not
    /// read/write the same persisted keys. Combine with `AccessibilityIdentifierConfig.$taskLocalConfig.withValue`.
    ///
    /// Do **not** rely on `AccessibilityIdentifierConfig.shared` from tests; it is global mutable state.
    @MainActor
    public static func makeIsolatedAccessibilityIdentifierConfig() -> AccessibilityIdentifierConfig {
        let suiteName = "SixLayer.Accessibility.Isolated.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create UserDefaults suite for accessibility test isolation: \(suiteName)")
        }
        let config = AccessibilityIdentifierConfig(
            userDefaults: defaults,
            keyPrefix: "Test.Accessibility.",
            suiteNameForIsolation: suiteName
        )
        config.resetToDefaults()
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        // Populate debug log during view build so helpers can fall back when UIKit does not expose identifiers (ViewInspector harness).
        config.enableDebugLogging = true
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableUITestIntegration = true
        config.currentScreenContext = "main"
        config.currentViewHierarchy = []
        return config
    }
    
    /// Setup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func setupTestEnvironment() {
        // Clear any existing test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    /// Cleanup test environment (placeholder - can be extended as needed)
    @MainActor
    public static func cleanupTestEnvironment() {
        // Clear all test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        HostingControllerStorage.tearDownActiveSession()
    }
}
