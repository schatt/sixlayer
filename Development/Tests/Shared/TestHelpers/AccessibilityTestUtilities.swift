//
//  AccessibilityTestUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Test utilities for accessibility identifier testing and HIG compliance verification
//

import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - Cross-platform hosting and accessibility utilities

/// Host a SwiftUI view and return the platform root view for inspection.
/// CRITICAL: The hosting controller is retained in static storage to prevent crashes
/// when the view is accessed after the function returns.
/// 
/// WARNING: This function can hang if the view contains NavigationStack/NavigationView
/// or complex hierarchies like GenericContentView in test environments without proper window hierarchy.
/// The hang occurs when accessing `hosting.view` - a synchronous UIKit/AppKit call that cannot be timed out.
/// 

/// Get accessibility identifier: ViewInspector (real hierarchy) when view is Inspectable, else platform fallback only.
#if canImport(ViewInspector)
@MainActor
public func getAccessibilityIdentifierForTest<V: View & ViewInspector.Inspectable>(view: V, hostedRoot: Any? = nil) -> String? {
    if let inspected = inspectView(view) {
        if let id = try? inspected.accessibilityIdentifier(), !id.isEmpty { return id }
        if let button = try? inspected.button(), let id = try? button.accessibilityIdentifier(), !id.isEmpty { return id }
    }
    guard let root = hostedRoot else { return nil }
    return firstAccessibilityIdentifier(inHosted: root)
}
#endif

#if canImport(ViewInspector)
/// Recursively find first non-empty accessibility identifier in ViewInspector hierarchy (for iOS when platform returns nil).
@MainActor
private func firstAccessibilityIdentifierInInspected(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) -> String? {
    if let id = try? inspected.accessibilityIdentifier(), !id.isEmpty { return id }
    let buttons = (try? inspected.findAll(ViewInspector.ViewType.Button.self)) ?? []
    for button in buttons {
        if let id = try? button.accessibilityIdentifier(), !id.isEmpty { return id }
    }
    return nil
}

/// Collect accessibility identifiers from inspected view (current node and one level of anyView + buttons).
@MainActor
private func allAccessibilityIdentifiersInInspected(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) -> [String] {
    var ids: [String] = []
    if let id = try? inspected.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    for button in (try? inspected.findAll(ViewInspector.ViewType.Button.self)) ?? [] {
        if let id = try? button.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    }
    // One level deeper: AnyView unwrap (modifier often wraps content in ModifiedContent + AnyView)
    guard let inner = try? inspected.anyView() else { return ids }
    if let id = try? inner.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    for button in (try? inner.findAll(ViewInspector.ViewType.Button.self)) ?? [] {
        if let id = try? button.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    }
    return ids
}
#endif

/// Get accessibility identifier when view is not Inspectable: try platform hierarchy first (IDs applied by SwiftUI), then ViewInspector (Issue 178).
@MainActor
public func getAccessibilityIdentifierForTest<V: View>(view: V, hostedRoot: Any? = nil) -> String? {
    #if canImport(ViewInspector)
    // Prefer platform hierarchy when available — SwiftUI applies modifiers to hosted views
    if let root = hostedRoot, let id = firstAccessibilityIdentifier(inHosted: root), !id.isEmpty {
        return id
    }
    if let inspected = try? AnyView(view).inspect() {
        if let id = firstAccessibilityIdentifierInInspected(inspected) { return id }
        if let inner = try? inspected.anyView() {
            if let id = try? inner.accessibilityIdentifier(), !id.isEmpty { return id }
            if let button = try? inner.button(), let id = try? button.accessibilityIdentifier(), !id.isEmpty { return id }
        }
        if let id = try? inspected.accessibilityIdentifier(), !id.isEmpty { return id }
        if let button = try? inspected.button(), let id = try? button.accessibilityIdentifier(), !id.isEmpty { return id }
    }
    #endif
    guard let root = hostedRoot else { return nil }
    return firstAccessibilityIdentifier(inHosted: root)
}

/// Get accessibility label: ViewInspector (real hierarchy) when view is Inspectable, else platform fallback only.
#if canImport(ViewInspector)
@MainActor
public func getAccessibilityLabelForTest<V: View & ViewInspector.Inspectable>(view: V, hostedRoot: Any? = nil) -> String? {
    if let inspected = inspectView(view) {
        if let labelView = try? inspected.accessibilityLabel(), let labelText = try? labelView.string(), !labelText.isEmpty {
            return labelText
        }
    }
    guard let root = hostedRoot else { return nil }
    return firstAccessibilityLabel(inHosted: root)
}
#endif

/// Get accessibility label when view is not Inspectable: try platform hierarchy first, then ViewInspector (Issue 178).
@MainActor
public func getAccessibilityLabelForTest<V: View>(view: V, hostedRoot: Any? = nil) -> String? {
    #if canImport(ViewInspector)
    if let root = hostedRoot, let label = firstAccessibilityLabel(inHosted: root), !label.isEmpty {
        return label
    }
    if let inspected = try? AnyView(view).inspect() {
        if let inner = try? inspected.anyView(),
           let labelView = try? inner.accessibilityLabel(),
           let labelText = try? labelView.string(), !labelText.isEmpty {
            return labelText
        }
        if let labelView = try? inspected.accessibilityLabel(),
           let labelText = try? labelView.string(), !labelText.isEmpty {
            return labelText
        }
    }
    #endif
    guard let root = hostedRoot else { return nil }
    return firstAccessibilityLabel(inHosted: root)
}

#if canImport(UIKit)
/// Return the first non-empty accessibility identifier from a view's accessibilityElements (SwiftUI may expose IDs there).
@MainActor
private func firstAccessibilityIdentifierFromElements(_ elements: [Any]?) -> String? {
    guard let elements = elements else { return nil }
    for element in elements {
        if let ax = element as? UIAccessibilityElement, let id = ax.accessibilityIdentifier, !id.isEmpty {
            return id
        }
    }
    return nil
}

/// Collect all non-empty accessibility identifiers from a view's accessibilityElements.
@MainActor
private func allAccessibilityIdentifiersFromElements(_ elements: [Any]?) -> [String] {
    guard let elements = elements else { return [] }
    var ids: [String] = []
    for element in elements {
        if let ax = element as? UIAccessibilityElement, let id = ax.accessibilityIdentifier, !id.isEmpty {
            ids.append(id)
        }
    }
    return ids
}

/// Return the first non-empty accessibility label from a view's accessibilityElements.
@MainActor
private func firstAccessibilityLabelFromElements(_ elements: [Any]?) -> String? {
    guard let elements = elements else { return nil }
    for element in elements {
        if let ax = element as? UIAccessibilityElement, let label = ax.accessibilityLabel, !label.isEmpty {
            return label
        }
    }
    return nil
}
#endif

/// Depth-first search for the first non-empty accessibility identifier in the platform view hierarchy.
/// Traverses up to 40 levels deep; also checks each view's accessibilityElements (SwiftUI may expose IDs there).
@MainActor
public func firstAccessibilityIdentifier(inHosted root: Any?) -> String? {
    #if canImport(UIKit)
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    guard let rootView = root as? UIView else { return nil }
    
    // Check root view first
    if let id = rootView.accessibilityIdentifier, !id.isEmpty {
        return id
    }
    // SwiftUI-hosted content may expose identifiers via accessibilityElements (Issue 178)
    if let id = firstAccessibilityIdentifierFromElements(rootView.accessibilityElements) {
        return id
    }
    
    let maxDepth = 40
    var stack: [(UIView, Int)] = rootView.subviews.map { ($0, 1) }
    var checkedViews: Set<ObjectIdentifier> = []
    
    while let (next, depth) = stack.popLast(), depth <= maxDepth {
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) { continue }
        checkedViews.insert(nextId)
        
        if let id = next.accessibilityIdentifier, !id.isEmpty {
            return id
        }
        if let id = firstAccessibilityIdentifierFromElements(next.accessibilityElements) {
            return id
        }
        if depth < maxDepth {
            // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
            stack.append(contentsOf: next.subviews.map { ($0, depth + 1) })
        }
    }
    return nil
    #elseif canImport(AppKit)
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    guard let rootView = root as? NSView else {
        return nil
    }
    
    // Check root view first
    let rootId = rootView.accessibilityIdentifier()
    if !rootId.isEmpty {
        return rootId
    }
    
    let maxDepth = 40
    var stack: [(NSView, Int)] = rootView.subviews.map { ($0, 1) }
    var checkedViews: Set<ObjectIdentifier> = []
    
    while let (next, depth) = stack.popLast(), depth <= maxDepth {
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) { continue }
        checkedViews.insert(nextId)
        
        let id = next.accessibilityIdentifier()
        if !id.isEmpty { return id }
        if depth < maxDepth {
            // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
            stack.append(contentsOf: next.subviews.map { ($0, depth + 1) })
        }
    }
    return nil
    #else
    return nil
    #endif
}

/// Depth-first search for the first non-empty accessibility label in the platform view hierarchy.
/// Also checks each view's accessibilityElements (SwiftUI may expose labels there).
@MainActor
public func firstAccessibilityLabel(inHosted root: Any?) -> String? {
    #if canImport(UIKit)
    guard let rootView = root as? UIView else { return nil }
    if let label = rootView.accessibilityLabel, !label.isEmpty { return label }
    if let label = firstAccessibilityLabelFromElements(rootView.accessibilityElements) {
        return label
    }
    var stack: [(UIView, Int)] = rootView.subviews.map { ($0, 1) }
    var checked: Set<ObjectIdentifier> = []
    while let (next, depth) = stack.popLast(), depth <= 40 {
        if checked.contains(ObjectIdentifier(next)) { continue }
        checked.insert(ObjectIdentifier(next))
        if let label = next.accessibilityLabel, !label.isEmpty { return label }
        if let label = firstAccessibilityLabelFromElements(next.accessibilityElements) {
            return label
        }
        if depth < 40 { stack.append(contentsOf: next.subviews.map { ($0, depth + 1) }) }
    }
    return nil
    #elseif canImport(AppKit)
    guard let rootView = root as? NSView else { return nil }
    if let label = rootView.accessibilityLabel(), !label.isEmpty { return label }
    var stack: [(NSView, Int)] = rootView.subviews.map { ($0, 1) }
    var checked: Set<ObjectIdentifier> = []
    while let (next, depth) = stack.popLast(), depth <= 40 {
        if checked.contains(ObjectIdentifier(next)) { continue }
        checked.insert(ObjectIdentifier(next))
        if let label = next.accessibilityLabel(), !label.isEmpty { return label }
        if depth < 40 { stack.append(contentsOf: next.subviews.map { ($0, depth + 1) }) }
    }
    return nil
    #else
    return nil
    #endif
}

/// Find ALL accessibility identifiers in a platform view hierarchy (not just the first one)
/// This is used as a fallback when ViewInspector is not available
/// Made public for navigation view tests that must bypass ViewInspector
@MainActor
public func findAllAccessibilityIdentifiersFromPlatformView(_ root: Any?) -> [String] {
    var identifiers: Set<String> = []
    
    #if canImport(UIKit)
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    guard let rootView = root as? UIView else { return [] }

    // Check root view and its accessibilityElements (SwiftUI may expose IDs there)
    if let id = rootView.accessibilityIdentifier, !id.isEmpty { identifiers.insert(id) }
    for id in allAccessibilityIdentifiersFromElements(rootView.accessibilityElements) { identifiers.insert(id) }

    // Search through all subviews
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    var stack: [UIView] = rootView.subviews
    var depth = 0
    var checkedViews: Set<ObjectIdentifier> = []
    var viewCount = 0
    let maxViews = 500 // Reduced limit to prevent hangs on very complex hierarchies
    
    while let next = stack.popLast(), depth < 20, viewCount < maxViews {
        viewCount += 1
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) {
            continue
        }
        // Prevent infinite loops from circular references
        if checkedViews.count > maxViews {
            break
        }
        checkedViews.insert(nextId)
        
        if let id = next.accessibilityIdentifier, !id.isEmpty { identifiers.insert(id) }
        for id in allAccessibilityIdentifiersFromElements(next.accessibilityElements) { identifiers.insert(id) }
        
        // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
        // Limit subviews to prevent excessive traversal
        let subviews = next.subviews
        if subviews.count > 20 {
            // For views with many subviews, only check first 20 to prevent hangs
            stack.append(contentsOf: subviews.prefix(20))
        } else {
            stack.append(contentsOf: subviews)
        }
        depth += 1
    }
    
    return Array(identifiers)
    #elseif canImport(AppKit)
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    guard let rootView = root as? NSView else { return [] }

    // Check root view
    let rootId = rootView.accessibilityIdentifier()
    if !rootId.isEmpty {
        identifiers.insert(rootId)
    }

    // Search through all subviews
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    var stack: [NSView] = rootView.subviews
    var depth = 0
    var checkedViews: Set<ObjectIdentifier> = []
    var viewCount = 0
    let maxViews = 500 // Reduced limit to prevent hangs on very complex hierarchies
    
    while let next = stack.popLast(), depth < 20, viewCount < maxViews {
        viewCount += 1
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) {
            continue
        }
        // Prevent infinite loops from circular references
        if checkedViews.count > maxViews {
            break
        }
        checkedViews.insert(nextId)
        
        let id = next.accessibilityIdentifier()
        if !id.isEmpty {
            identifiers.insert(id)
        }
        
        // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
        // Limit subviews to prevent excessive traversal
        let subviews = next.subviews
        if subviews.count > 20 {
            // For views with many subviews, only check first 20 to prevent hangs
            stack.append(contentsOf: subviews.prefix(20))
        } else {
            stack.append(contentsOf: subviews)
        }
        depth += 1
    }
    
    return Array(identifiers)
    #else
    return []
    #endif
}

/// Test utilities for accessibility identifier testing
public enum AccessibilityTestUtilities {
    
    // MARK: - Test Functions
    
    /// Inspect a SwiftUI view using ViewInspector and attempt to retrieve the
    /// accessibility identifier from an underlying Button. This centralizes the
    /// common pattern used across accessibility tests.
    @MainActor
    public static func inspectButtonAccessibilityIdentifier<V: View>(
        _ view: V,
        issuePrefix: String = "Failed to inspect view for accessibility identifier"
    ) -> String? {
        #if canImport(ViewInspector)
        do {
            let inspected = try AnyView(view).inspect()
            if let inner = try? inspected.anyView() {
                if let directID = try? inner.accessibilityIdentifier(), !directID.isEmpty { return directID }
                if let button = try? inner.button(), let buttonID = try? button.accessibilityIdentifier(), !buttonID.isEmpty { return buttonID }
            }
            if let directID = try? inspected.accessibilityIdentifier(), !directID.isEmpty { return directID }
            if let button = try? inspected.button(), let buttonID = try? button.accessibilityIdentifier(), !buttonID.isEmpty { return buttonID }
            // If we reach here, ViewInspector couldn't find an identifier. This is
            // treated as an inspection limitation rather than a hard failure; the
            // caller can decide whether to assert or treat it as "cannot verify".
            return nil
        } catch {
            Issue.record("\(issuePrefix): \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Test accessibility identifiers for a view on a single platform.
    /// Returns true only if at least one accessibility identifier in the view hierarchy
    /// matches the expected pattern (prefix) or contains the component name.
    /// Uses platform hosting (with task-local config) then ViewInspector collection.
    /// Some views may not expose identifiers in unit-test hosting; those tests will fail until the environment is fixed.
    @MainActor
    public static func testComponentComplianceSinglePlatform<V: View>(
        _ view: V,
        expectedPattern: String,
        platform: SixLayerPlatform,
        componentName: String,
        testHIGCompliance: Bool = true
    ) -> Bool {
        func identifierMatches(_ id: String) -> Bool {
            let prefix = expectedPattern.replacingOccurrences(of: ".*", with: "")
            return id.hasPrefix(prefix) || id.contains(componentName)
        }
        #if canImport(UIKit) || canImport(AppKit)
        // Host view with task-local config so automaticCompliance generates identifiers (namespace "SixLayer", etc.)
        let testDefaults = UserDefaults(suiteName: "SixLayer.A11yTestHelper") ?? .standard
        let config = AccessibilityIdentifierConfig(userDefaults: testDefaults, keyPrefix: "Test.A11y.")
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        config.namespace = "SixLayer"
        config.enableUITestIntegration = true
        let root: Any? = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
        }
        if let root = root {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            if ids.contains(where: identifierMatches) { return true }
        }
        #endif
        #if canImport(ViewInspector)
        // Fallback: ViewInspector – collect all identifiers from inspected hierarchy and check for match
        do {
            let inspected = try AnyView(view).inspect()
            let allIds = allAccessibilityIdentifiersInInspected(inspected)
            if allIds.contains(where: identifierMatches) { return true }
        } catch {
            return false
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Test accessibility identifiers for a view across platforms.
    /// Returns true only if at least one accessibility identifier matches the expected pattern or contains the component name.
    @MainActor
    public static func testAccessibilityIdentifiersCrossPlatform<V: View>(
        _ view: V,
        expectedPattern: String,
        componentName: String,
        testName: String? = nil
    ) -> Bool {
        return testComponentComplianceSinglePlatform(
            view,
            expectedPattern: expectedPattern,
            platform: SixLayerPlatform.current,
            componentName: componentName,
            testHIGCompliance: true
        )
    }
    
    /// Cleanup accessibility test environment
    public static func cleanupAccessibilityTestEnvironment() async {
        // Clear any test overrides
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        // Reset accessibility config if needed
        await MainActor.run {
            AccessibilityIdentifierConfig.shared.resetToDefaults()
        }
    }
}

// MARK: - Global Function Aliases

/// Global function alias for testComponentComplianceSinglePlatform
@MainActor
public func testComponentComplianceSinglePlatform<V: View>(
    _ view: V,
    expectedPattern: String,
    platform: SixLayerPlatform,
    componentName: String,
    testHIGCompliance: Bool = true
) -> Bool {
    return AccessibilityTestUtilities.testComponentComplianceSinglePlatform(
        view,
        expectedPattern: expectedPattern,
        platform: platform,
        componentName: componentName,
        testHIGCompliance: testHIGCompliance
    )
}

/// Global function alias for testAccessibilityIdentifiersCrossPlatform
@MainActor
public func testAccessibilityIdentifiersCrossPlatform<V: View>(
    _ view: V,
    expectedPattern: String,
    componentName: String,
    testName: String? = nil
) -> Bool {
    return AccessibilityTestUtilities.testAccessibilityIdentifiersCrossPlatform(
        view,
        expectedPattern: expectedPattern,
        componentName: componentName,
        testName: testName
    )
}

/// Global function alias for testComponentComplianceCrossPlatform (same as testAccessibilityIdentifiersCrossPlatform)
@MainActor
public func testComponentComplianceCrossPlatform<V: View>(
    _ view: V,
    expectedPattern: String,
    componentName: String
) -> Bool {
    return AccessibilityTestUtilities.testAccessibilityIdentifiersCrossPlatform(
        view,
        expectedPattern: expectedPattern,
        componentName: componentName
    )
}
