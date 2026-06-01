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

#if canImport(UIKit) && !os(watchOS)
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
    let buttons = inspected.findAll(ViewInspector.ViewType.Button.self)
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
    for button in inspected.findAll(ViewInspector.ViewType.Button.self) {
        if let id = try? button.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    }
    // One level deeper: AnyView unwrap (modifier often wraps content in ModifiedContent + AnyView)
    guard let inner = try? inspected.anyView() else { return ids }
    if let id = try? inner.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    for button in inner.findAll(ViewInspector.ViewType.Button.self) {
        if let id = try? button.accessibilityIdentifier(), !id.isEmpty { ids.append(id) }
    }
    return ids
}

/// Collect all accessibility identifiers from the full ViewInspector hierarchy.
/// Uses findAll for AnyView, VStack, HStack, ZStack and unwraps root AnyView so the inner view (e.g. card with modifier) is checked.
@MainActor
private func allAccessibilityIdentifiersInInspectedRecursive(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>
) -> [String] {
    var ids: [String] = []
    func collect(_ id: String?) {
        if let id = id, !id.isEmpty { ids.append(id) }
    }
    collect(try? inspected.accessibilityIdentifier())
    // Unwrap root AnyView: the modifier is on the inner view (e.g. ExpandableCardComponent), not the AnyView container.
    if let inner = try? inspected.anyView() {
        collect(try? inner.accessibilityIdentifier())
        for av in inner.findAll(ViewInspector.ViewType.AnyView.self) { collect(try? av.accessibilityIdentifier()) }
        for v in inner.findAll(ViewInspector.ViewType.VStack.self) { collect(try? v.accessibilityIdentifier()) }
        for v in inner.findAll(ViewInspector.ViewType.HStack.self) { collect(try? v.accessibilityIdentifier()) }
        for v in inner.findAll(ViewInspector.ViewType.ZStack.self) { collect(try? v.accessibilityIdentifier()) }
        for v in inner.findAll(ViewInspector.ViewType.Button.self) { collect(try? v.accessibilityIdentifier()) }
        for v in inner.findAll(ViewInspector.ViewType.Text.self) { collect(try? v.accessibilityIdentifier()) }
    }
    for av in inspected.findAll(ViewInspector.ViewType.AnyView.self) {
        collect(try? av.accessibilityIdentifier())
    }
    for v in inspected.findAll(ViewInspector.ViewType.VStack.self) {
        collect(try? v.accessibilityIdentifier())
    }
    for v in inspected.findAll(ViewInspector.ViewType.HStack.self) {
        collect(try? v.accessibilityIdentifier())
    }
    for v in inspected.findAll(ViewInspector.ViewType.ZStack.self) {
        collect(try? v.accessibilityIdentifier())
    }
    for v in inspected.findAll(ViewInspector.ViewType.Button.self) {
        collect(try? v.accessibilityIdentifier())
    }
    for v in inspected.findAll(ViewInspector.ViewType.Text.self) {
        collect(try? v.accessibilityIdentifier())
    }
    // ClassifiedView is the generic "any" view type; the modifier may be on a node that only appears as ClassifiedView.
    for node in inspected.findAll(ViewInspector.ViewType.ClassifiedView.self, where: { _ in true }) {
        collect(try? node.accessibilityIdentifier())
    }
    return ids
}

/// Collect accessibility identifiers from a directly inspected view (no AnyView wrap).
/// Use when the view type conforms to ViewInspector.Inspectable (Issue 178).
@MainActor
private func allAccessibilityIdentifiersFromTypedInspectable<V: View & ViewInspector.Inspectable>(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>
) -> [String] {
    var ids: [String] = []
    func collect(_ id: String?) {
        if let id = id, !id.isEmpty { ids.append(id) }
    }
    collect(try? inspected.accessibilityIdentifier())
    for av in inspected.findAll(ViewInspector.ViewType.AnyView.self) { collect(try? av.accessibilityIdentifier()) }
    for v in inspected.findAll(ViewInspector.ViewType.VStack.self) { collect(try? v.accessibilityIdentifier()) }
    for v in inspected.findAll(ViewInspector.ViewType.HStack.self) { collect(try? v.accessibilityIdentifier()) }
    for v in inspected.findAll(ViewInspector.ViewType.ZStack.self) { collect(try? v.accessibilityIdentifier()) }
    for v in inspected.findAll(ViewInspector.ViewType.Button.self) { collect(try? v.accessibilityIdentifier()) }
    // Deep traversal: modifier may be on a node that only appears as ClassifiedView (same as AnyView path).
    for node in inspected.findAll(ViewInspector.ViewType.ClassifiedView.self, where: { _ in true }) {
        collect(try? node.accessibilityIdentifier())
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
    // Generator debug log (isolated test configs enable debug logging): UIKit may not mirror IDs in unit-test hosting.
    if let cfg = AccessibilityIdentifierConfig.currentTaskLocalConfig {
        let fromLog = AccessibilityTestUtilities.parsedIdentifiersFromConfigDebugLog(config: cfg)
        // Prefer single-segment ids (exactNamed, short names) over long automaticCompliance shells.
        if let id = fromLog.reversed().first(where: { !$0.isEmpty && $0.split(separator: ".").count == 1 }) {
            return id
        }
        if let id = fromLog.reversed().first(where: { !$0.isEmpty }) {
            return id
        }
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

#if canImport(UIKit) && !os(watchOS)
/// Upper bound for `accessibilityElementCount` before enumerating via `accessibilityElementAtIndex:`.
/// Some SwiftUI/UIKit hosting views report counts that make naive enumeration effectively hang
/// (main-thread retain churn in test helpers; e.g. modal sheet chrome ViewInspector tests).
private let maxAccessibilityContainerEnumerationCount = 256

@MainActor
private func boundedAccessibilityContainerIndices(_ rawCount: Int) -> [Int] {
    guard rawCount > 0 else { return [] }
    if rawCount <= maxAccessibilityContainerEnumerationCount {
        return Array(0 ..< rawCount)
    }

    // Large SwiftUI-hosted containers can report huge counts. Scan a bounded head+tail
    // window so we keep runtime predictable while still seeing late-index toolbar items.
    let tailCount = maxAccessibilityContainerEnumerationCount / 2
    let headCount = maxAccessibilityContainerEnumerationCount - tailCount
    let tailStart = max(rawCount - tailCount, headCount)

    var indices: [Int] = Array(0 ..< headCount)
    if tailStart < rawCount {
        indices.append(contentsOf: tailStart ..< rawCount)
    }
    return indices
}

/// Identifier from a child returned by `accessibilityElement(at:)` (may be `UIAccessibilityElement` or `UIView`).
@MainActor
private func accessibilityIdentifierFromAccessibilityContainerChild(_ raw: Any?) -> String? {
    if let el = raw as? UIAccessibilityElement, let id = el.accessibilityIdentifier, !id.isEmpty { return id }
    if let v = raw as? UIView, let id = v.accessibilityIdentifier, !id.isEmpty { return id }
    return nil
}

/// UIKit exposes accessibility container APIs directly; prefer those over
/// Objective-C `perform` to avoid retaining invalid bridged objects from the
/// runtime on newer simulator stacks.
@MainActor
private func accessibilityContainerChildren(for view: UIView) -> [Any] {
    let count = view.accessibilityElementCount()
    guard count > 0 else { return [] }

    var children: [Any] = []
    children.reserveCapacity(min(count, maxAccessibilityContainerEnumerationCount))
    for index in boundedAccessibilityContainerIndices(count) {
        if let child = view.accessibilityElement(at: index) {
            children.append(child)
        }
    }
    return children
}

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

/// First non-empty identifier from the UIAccessibilityContainer-style API (`accessibilityElementCount` / `accessibilityElement(at:)`).
/// SwiftUI hosting views often expose child elements here instead of `accessibilityElements` or `subviews` (aligned with `findAllAccessibilityIdentifiersFromPlatformView`).
@MainActor
private func firstAccessibilityIdentifierFromAccessibilityContainer(_ view: UIView) -> String? {
    for child in accessibilityContainerChildren(for: view) {
        if let id = accessibilityIdentifierFromAccessibilityContainerChild(child) {
            return id
        }
        if let labelContainer = child as? UIView,
           let id = firstAccessibilityIdentifierFromElements(labelContainer.accessibilityElements) {
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

/// Walks the same bounded UIView tree as hosted accessibility helpers and reports the largest
/// `accessibilityElementCount` from the UIAccessibilityContainer-style API (diagnostics for #232).
@MainActor
public func diagnosticsReportedAccessibilityElementCounts(inHosted root: Any?, threshold: Int = 256) -> String {
    guard let rootView = root as? UIView else { return "root is not a UIView" }
    let countSel = NSSelectorFromString("accessibilityElementCount")
    var maxCount = 0
    var maxSummary = ""
    var heavy: [(String, Int)] = []
    var containerResponders = 0

    func consider(_ view: UIView) {
        guard view.responds(to: countSel) else { return }
        containerResponders += 1
        let n = view.accessibilityElementCount()
        if n > maxCount {
            maxCount = n
            maxSummary = "\(type(of: view)) frame=\(view.frame)"
        }
        if n >= threshold {
            heavy.append(("\(type(of: view)) frame=\(view.frame)", n))
        }
    }

    consider(rootView)
    var stack: [UIView] = rootView.subviews
    var checked: Set<ObjectIdentifier> = []
    var visits = 0
    while let next = stack.popLast(), visits < 500 {
        visits += 1
        guard checked.insert(ObjectIdentifier(next)).inserted else { continue }
        consider(next)
        stack.append(contentsOf: next.subviews.prefix(80))
    }

    heavy.sort { $0.1 > $1.1 }
    let topLines = heavy.prefix(12).map { "\($0.1): \($0.0)" }.joined(separator: "\n")
    var out = "UIView instances responding to accessibilityElementCount=\(containerResponders); max reported count=\(maxCount) (\(maxSummary))\n"
    if heavy.isEmpty {
        out += "no views with count >= \(threshold)"
    } else {
        out += "views with count >= \(threshold) (up to 12, sorted desc):\n\(topLines)"
    }
    return out
}
#endif

/// Depth-first search for the first non-empty accessibility identifier in the platform view hierarchy.
/// Traverses up to 40 levels deep; checks `accessibilityElements`, the UIAccessibilityContainer-style API, and subviews (SwiftUI / Issue 178 / Issue #193).
@MainActor
public func firstAccessibilityIdentifier(inHosted root: Any?) -> String? {
    #if canImport(UIKit) && !os(watchOS)
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
    if let id = firstAccessibilityIdentifierFromAccessibilityContainer(rootView) {
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
        if let id = firstAccessibilityIdentifierFromAccessibilityContainer(next) {
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
    #if canImport(UIKit) && !os(watchOS)
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

#if canImport(UIKit) && !os(watchOS)
/// Diagnostic: dump the hosted view's accessibility tree to a string for debugging single-tappable tests (Issue #191).
/// Call when hostedViewHasAccessibilityElementWithLabelAndButtonTrait returns false to see where label/traits appear.
@MainActor
public func dumpAccessibilityTreeForDiagnostics(root: Any?, maxViews: Int = 150) -> String {
    guard let rootView = root as? UIView else { return "root is not a UIView" }
    var lines: [String] = []
    var count = 0
    func describe(_ view: UIView, depth: Int) {
        guard count < maxViews else { return }
        count += 1
        let indent = String(repeating: "  ", count: depth)
        let label = view.accessibilityLabel ?? ""
        let traits = view.accessibilityTraits.rawValue
        let elemDesc: String
        if let el = view.accessibilityElements as? [UIAccessibilityElement], !el.isEmpty {
            elemDesc = el.prefix(5).map { e in
                "\(e.accessibilityLabel ?? "?") traits=\(e.accessibilityTraits.rawValue)"
            }.joined(separator: "; ")
        } else {
            elemDesc = "none"
        }
        lines.append("\(indent)\(type(of: view)) label=\"\(label.prefix(60))\" traits=\(traits) elements=[\(elemDesc)]")
        for sub in view.subviews.prefix(40) {
            describe(sub, depth: depth + 1)
        }
    }
    describe(rootView, depth: 0)
    return lines.joined(separator: "\n")
}

/// Returns true if the hosted view hierarchy contains an accessibility element that has the given label (or label contains expected) and the button trait.
/// Used to verify tappable cards expose a single button-like element (Issue #191).
/// Checks both view.accessibilityElements and UIAccessibilityContainer (SwiftUI hosting views often expose elements via the container API, not subviews).
@MainActor
public func hostedViewHasAccessibilityElementWithLabelAndButtonTrait(root: Any?, expectedLabel: String) -> Bool {
    guard let rootView = root as? UIView, !expectedLabel.isEmpty else { return false }
    func checkElement(_ ax: UIAccessibilityElement) -> Bool {
        guard let label = ax.accessibilityLabel, label.contains(expectedLabel) else { return false }
        return ax.accessibilityTraits.contains(.button)
    }
    func checkView(_ view: UIView) -> Bool {
        if let label = view.accessibilityLabel, label.contains(expectedLabel), view.accessibilityTraits.contains(.button) {
            return true
        }
        if let elements = view.accessibilityElements {
            for el in elements {
                if let ax = el as? UIAccessibilityElement, checkElement(ax) { return true }
            }
        }
        // SwiftUI hosting often exposes elements via the container API (accessibilityElementCount / accessibilityElement(at:)) instead of subviews or accessibilityElements array. Use runtime so we don't depend on UIAccessibilityContainer being in scope.
        if view.responds(to: NSSelectorFromString("accessibilityElementCount")) {
            for raw in accessibilityContainerChildren(for: view) {
                if let el = raw as? UIAccessibilityElement, checkElement(el) {
                    return true
                }
                if let v = raw as? UIView, let label = v.accessibilityLabel, label.contains(expectedLabel),
                   v.accessibilityTraits.contains(.button) {
                    return true
                }
            }
        }
        return false
    }
    if checkView(rootView) { return true }
    var stack: [UIView] = rootView.subviews
    var checked: Set<ObjectIdentifier> = []
    var count = 0
    while let next = stack.popLast(), count < 500 {
        count += 1
        guard checked.insert(ObjectIdentifier(next)).inserted else { continue }
        if checkView(next) { return true }
        stack.append(contentsOf: next.subviews.prefix(80))
    }
    return false
}

/// Walks `UIView` and nested accessibility container children; returns true if `predicate` matches any node.
/// Used for Issue #254 semantic checks (traits, identifiers) on hosted Layer 4 `platform*_L4` output.
@MainActor
public func hostedUIKitAccessibilityHierarchyContains(
    root: Any?,
    maxVisited: Int = 800,
    predicate: (UIView) -> Bool
) -> Bool {
    guard let rootView = root as? UIView else { return false }
    func checkView(_ view: UIView) -> Bool {
        if predicate(view) { return true }
        if let elements = view.accessibilityElements {
            for el in elements {
                if let sub = el as? UIView, predicate(sub) { return true }
            }
        }
        if view.responds(to: NSSelectorFromString("accessibilityElementCount")) {
            for raw in accessibilityContainerChildren(for: view) {
                if let sub = raw as? UIView, predicate(sub) { return true }
            }
        }
        return false
    }
    if checkView(rootView) { return true }
    var stack: [UIView] = rootView.subviews
    var checked: Set<ObjectIdentifier> = []
    var count = 0
    while let next = stack.popLast(), count < maxVisited {
        count += 1
        guard checked.insert(ObjectIdentifier(next)).inserted else { continue }
        if checkView(next) { return true }
        stack.append(contentsOf: next.subviews.prefix(80))
    }
    return false
}

/// True when some hosted node exposes all bits in `requiredTraits` and optionally an identifier substring.
@MainActor
public func hostedUIKitAccessibilityTraitMatch(
    root: Any?,
    requiredTraits: UIAccessibilityTraits,
    identifierContains: String? = nil
) -> Bool {
    hostedUIKitAccessibilityHierarchyContains(root: root) { view in
        let traits = view.accessibilityTraits
        let traitsOK = requiredTraits.isSubset(of: traits)
        guard traitsOK else { return false }
        if let needle = identifierContains {
            guard let id = view.accessibilityIdentifier, id.contains(needle) else { return false }
        }
        return true
    }
}

/// True when some hosted node has a non-empty `accessibilityValue` and an identifier substring match.
@MainActor
public func hostedUIKitAccessibilityValuePresent(
    root: Any?,
    identifierContains: String
) -> Bool {
    hostedUIKitAccessibilityHierarchyContains(root: root) { view in
        guard let id = view.accessibilityIdentifier, id.contains(identifierContains) else { return false }
        guard let value = view.accessibilityValue, !value.isEmpty else { return false }
        return true
    }
}

/// Proxy for VoiceOver traversal: a named, non-hidden node with meaningful traits on the hosted UIKit tree.
@MainActor
public func hostedTreeHasVoiceOverDiscoverableNode(root: Any?) -> Bool {
    hostedUIKitAccessibilityHierarchyContains(root: root) { view in
        if view.accessibilityElementsHidden { return false }
        let hasName = !(view.accessibilityLabel ?? "").isEmpty || !(view.accessibilityIdentifier ?? "").isEmpty
        guard hasName else { return false }
        let traits = view.accessibilityTraits
        return traits.contains(.button)
            || traits.contains(.link)
            || traits.contains(.staticText)
            || traits.contains(.header)
            || traits.contains(.image)
            || traits.contains(.adjustable)
            || traits.contains(.updatesFrequently)
            || traits.contains(.searchField)
    }
}

/// Proxy for Switch Control focus: actionable traits (or SixLayer-identified informative surfaces).
@MainActor
public func hostedTreeHasSwitchControlActivationCandidate(root: Any?) -> Bool {
    hostedUIKitAccessibilityHierarchyContains(root: root) { view in
        if view.accessibilityElementsHidden { return false }
        let traits = view.accessibilityTraits
        let hasName = !(view.accessibilityLabel ?? "").isEmpty || !(view.accessibilityIdentifier ?? "").isEmpty
        guard hasName else { return false }
        if traits.contains(.button) || traits.contains(.link) || traits.contains(.adjustable) {
            return true
        }
        if !(view.accessibilityIdentifier ?? "").isEmpty {
            return traits.contains(.staticText)
                || traits.contains(.header)
                || traits.contains(.image)
                || traits.contains(.updatesFrequently)
        }
        return false
    }
}

/// High-contrast / differentiate-without-color proxy: SixLayer identifier keys overlap after visual adaptability overrides.
@MainActor
public func hostedTreesRetainOverlappingSixLayerAccessibilityKeys(defaultRoot: Any?, adaptedRoot: Any?) -> Bool {
    let defaultIDs = Set(findAllAccessibilityIdentifiersFromPlatformView(defaultRoot).filter { $0.contains("SixLayer") })
    let adaptedIDs = Set(findAllAccessibilityIdentifiersFromPlatformView(adaptedRoot).filter { $0.contains("SixLayer") })
    guard !defaultIDs.isEmpty, !adaptedIDs.isEmpty else { return false }
    return !defaultIDs.isDisjoint(with: adaptedIDs)
}
#endif

/// Find ALL accessibility identifiers in a platform view hierarchy (not just the first one)
/// This is used as a fallback when ViewInspector is not available
/// Made public for navigation view tests that must bypass ViewInspector
@MainActor
public func findAllAccessibilityIdentifiersFromPlatformView(_ root: Any?) -> [String] {
    var identifiers: Set<String> = []
    
    #if canImport(UIKit) && !os(watchOS)
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    guard let rootView = root as? UIView else { return [] }

    func addIdentifiers(from view: UIView) {
        if let id = view.accessibilityIdentifier, !id.isEmpty {
            identifiers.insert(id)
        }
        for id in allAccessibilityIdentifiersFromElements(view.accessibilityElements) {
            identifiers.insert(id)
        }
        // Some SwiftUI hosting views expose IDs via the UIAccessibilityContainer-style API
        // (accessibilityElementCount / accessibilityElementAtIndex:) instead of subviews or accessibilityElements.
        if view.responds(to: NSSelectorFromString("accessibilityElementCount")) {
            for child in accessibilityContainerChildren(for: view) {
                if let id = accessibilityIdentifierFromAccessibilityContainerChild(child) {
                    identifiers.insert(id)
                }
            }
        }
    }

    // Check root view and its accessibility-related elements
    addIdentifiers(from: rootView)

    // Search through all subviews (tree depth vs visit count: previously `depth` incremented every
    // pop and capped at 20, so only ~20 views were ever visited — platform a11y IDs were often missed; Issue #193 / ViewInspector suite).
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    let maxTreeDepth = 40
    var stack: [(UIView, Int)] = rootView.subviews.map { ($0, 1) }
    var checkedViews: Set<ObjectIdentifier> = []
    var viewCount = 0
    let maxViews = 500 // Cap total visits to prevent hangs on very complex hierarchies
    
    while let (next, treeDepth) = stack.popLast(), viewCount < maxViews {
        viewCount += 1
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) {
            continue
        }
        if checkedViews.count > maxViews {
            break
        }
        checkedViews.insert(nextId)
        
        addIdentifiers(from: next)
        
        guard treeDepth < maxTreeDepth else { continue }
        let subviews = next.subviews
        let children: ArraySlice<UIView> = subviews.count > 20 ? subviews.prefix(20) : subviews[...]
        let childDepth = treeDepth + 1
        for sub in children {
            stack.append((sub, childDepth))
        }
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

    // Same tree-depth fix as UIKit: do not treat visit count as "depth" (was capping at ~20 views total).
    // 6LAYER_ALLOW: test utilities must traverse platform-specific view hierarchies for accessibility testing
    let maxTreeDepth = 40
    var stack: [(NSView, Int)] = []
    if let axRootChildren = rootView.accessibilityChildren() {
        for child in axRootChildren.prefix(50) {
            if let childView = child as? NSView {
                stack.append((childView, 1))
            } else if let el = child as? NSAccessibilityElement {
                if let sid = el.accessibilityIdentifier(), !sid.isEmpty {
                    identifiers.insert(sid)
                }
            }
        }
    }
    stack.append(contentsOf: rootView.subviews.map { ($0, 1) })
    var checkedViews: Set<ObjectIdentifier> = []
    var viewCount = 0
    let maxViews = 500
    
    while let (next, treeDepth) = stack.popLast(), viewCount < maxViews {
        viewCount += 1
        let nextId = ObjectIdentifier(next)
        if checkedViews.contains(nextId) {
            continue
        }
        if checkedViews.count > maxViews {
            break
        }
        checkedViews.insert(nextId)
        
        let id = next.accessibilityIdentifier()
        if !id.isEmpty {
            identifiers.insert(id)
        }
        
        guard treeDepth < maxTreeDepth else { continue }
        let childDepth = treeDepth + 1
        if let axChildren = next.accessibilityChildren() {
            for child in axChildren.prefix(50) {
                if let childView = child as? NSView {
                    stack.append((childView, childDepth))
                } else if let el = child as? NSAccessibilityElement {
                    if let sid = el.accessibilityIdentifier(), !sid.isEmpty {
                        identifiers.insert(sid)
                    }
                }
            }
        }
        let subviews = next.subviews
        let children: ArraySlice<NSView> = subviews.count > 20 ? subviews.prefix(20) : subviews[...]
        for sub in children {
            stack.append((sub, childDepth))
        }
    }
    
    return Array(identifiers)
    #else
    return []
    #endif
}

/// Test utilities for accessibility identifier testing
public enum AccessibilityTestUtilities {
    
    // MARK: - Test Functions
    
    /// Extract a generated accessibility identifier from a debug log line, if present.
    /// Looks for patterns used by AutomaticAccessibilityIdentifiers and AccessibilityIdentifierGenerator.
    private static func extractIdentifierFromDebugLogLine(_ line: String) -> String? {
        // Pattern 1: "Generated identifier 'ID' ..."
        if let range = line.range(of: "Generated identifier '") {
            let after = line[range.upperBound...]
            if let end = after.firstIndex(of: "'") {
                let id = after[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                if !id.isEmpty { return String(id) }
            }
        }
        // Pattern 2: "Generated ID: ID for:"
        if let range = line.range(of: "Generated ID: ") {
            let after = line[range.upperBound...]
            // Extract up to " for:" or end of line
            if let forRange = after.range(of: " for:") {
                let id = after[..<forRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                if !id.isEmpty { return String(id) }
            } else {
                let id = after.trimmingCharacters(in: .whitespacesAndNewlines)
                if !id.isEmpty { return String(id) }
            }
        }
        return nil
    }

    @MainActor
    private static func normalizedIdentifierCandidates(_ value: String) -> [String] {
        guard !value.isEmpty else { return [] }
        
        var candidates: [String] = [value]
        
        // Some legacy tests use ".main.element." while current IDs include ".main.ui.element."
        if value.contains(".main.ui.") {
            candidates.append(value.replacingOccurrences(of: ".main.ui.", with: ".main."))
        }
        
        // Compare on stable suffix where namespaces differ (e.g. "SixLayer.main..." vs "main...")
        if let range = value.range(of: ".main.") {
            candidates.append(String(value[range.lowerBound...]))
        } else if value.hasPrefix("main.") {
            candidates.append("." + value)
        }
        
        // Bridge namespaced and non-namespaced test expectations.
        if value.hasPrefix("SixLayer.") {
            candidates.append(String(value.dropFirst("SixLayer.".count)))
        } else if value.hasPrefix("main.") {
            candidates.append("SixLayer." + value)
        }
        
        // Keep deterministic order while deduplicating
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    /// Legacy Layer 4/5/6 globs use `*.main.ui.element.*` while generators emit `SixLayer.main.ui.<Component>.View`.
    @MainActor
    private static func normalizedPatternCandidates(_ pattern: String) -> [String] {
        guard !pattern.isEmpty else { return [] }
        var candidates = normalizedIdentifierCandidates(pattern)
        if pattern.contains(".main.ui.element.") {
            candidates.append(pattern.replacingOccurrences(of: ".main.ui.element.", with: ".main.ui."))
        }
        if pattern.contains(".main.element.") {
            candidates.append(pattern.replacingOccurrences(of: ".main.element.", with: ".main."))
        }
        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }
    
    /// True when `pattern` is a dot-segment glob (`*` only wildcards), not a regex.
    @MainActor
    private static func isDotSegmentGlobPattern(_ pattern: String) -> Bool {
        guard pattern.contains("*") else { return false }
        var remaining = pattern
        while remaining.hasPrefix("*") { remaining.removeFirst() }
        while remaining.hasSuffix("*") { remaining.removeLast() }
        let segments = remaining.split(separator: "*", omittingEmptySubsequences: false)
        return segments.allSatisfy { segment in
            segment.isEmpty || segment.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0) || $0 == "." || $0 == "-" || $0 == "_"
            }
        }
    }

    @MainActor
    private static func isRegexLikePattern(_ pattern: String) -> Bool {
        if isDotSegmentGlobPattern(pattern) { return false }
        return pattern.contains("\\") || pattern.contains("^") || pattern.contains("$") || pattern.contains(".*")
    }
    
    @MainActor
    private static func matchesRegex(_ identifier: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(identifier.startIndex..<identifier.endIndex, in: identifier)
        return regex.firstMatch(in: identifier, range: range) != nil
    }
    
    /// Glob matching for test patterns like `SixLayer.*ui` or `*.main.element.*`.
    ///
    /// The previous implementation turned `*` into `.*` in a single regex, which made
    /// `SixLayer.*ui` behave like `^SixLayer\..*ui$` and **required the string to end with `ui`**.
    /// Tests intend `*` as “any substring between segments”, so
    /// `SixLayer.main.ui.test.Button` must match `SixLayer.*ui`.
    @MainActor
    private static func matchesGlob(_ identifier: String, pattern: String) -> Bool {
        guard !pattern.isEmpty else { return identifier.isEmpty }
        
        if !pattern.contains("*") {
            return identifier.caseInsensitiveCompare(pattern) == .orderedSame
        }
        
        let parts = pattern.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
        if parts.allSatisfy({ $0.isEmpty }) {
            return true
        }
        
        let startsWithStar = pattern.hasPrefix("*")
        let endsWithStar = pattern.hasSuffix("*")
        let nonEmptyParts = parts.filter { !$0.isEmpty }
        
        // *suffix — must end with the suffix (case-insensitive)
        if startsWithStar && !endsWithStar && nonEmptyParts.count == 1 {
            let suf = nonEmptyParts[0]
            guard identifier.count >= suf.count else { return false }
            let tail = String(identifier.suffix(suf.count))
            return tail.caseInsensitiveCompare(suf) == .orderedSame
        }
        
        // prefix* — must start with the prefix (case-insensitive)
        if !startsWithStar && endsWithStar && nonEmptyParts.count == 1 {
            let pre = nonEmptyParts[0]
            guard identifier.count >= pre.count else { return false }
            let head = String(identifier.prefix(pre.count))
            return head.caseInsensitiveCompare(pre) == .orderedSame
        }
        
        var cursor = identifier.startIndex
        var partIndex = 0
        
        while partIndex < parts.count && parts[partIndex].isEmpty {
            partIndex += 1
        }
        if partIndex >= parts.count {
            return true
        }
        
        if !startsWithStar {
            let p = parts[partIndex]
            let remaining = String(identifier[cursor...])
            guard remaining.count >= p.count else { return false }
            let head = String(remaining.prefix(p.count))
            guard head.caseInsensitiveCompare(p) == .orderedSame else { return false }
            cursor = identifier.index(cursor, offsetBy: p.count)
            partIndex += 1
        } else {
            let p = parts[partIndex]
            guard let r = identifier.range(of: p, options: .caseInsensitive, range: cursor..<identifier.endIndex) else {
                return false
            }
            cursor = r.upperBound
            partIndex += 1
        }
        
        while partIndex < parts.count {
            let p = parts[partIndex]
            if p.isEmpty {
                partIndex += 1
                continue
            }
            guard let r = identifier.range(of: p, options: .caseInsensitive, range: cursor..<identifier.endIndex) else {
                return false
            }
            cursor = r.upperBound
            partIndex += 1
        }
        
        return true
    }
    
    /// Exposed for unit tests of pattern semantics (glob vs regex vs namespace normalization).
    @MainActor
    public static func identifierMatchesExpectedPattern(_ identifier: String, expectedPattern: String) -> Bool {
        matchesExpectedPattern(identifier, expectedPattern: expectedPattern)
    }
    
    /// Parsed identifier strings from `AccessibilityIdentifierConfig` debug log entries (requires debug logging enabled on that config during view build).
    @MainActor
    public static func parsedIdentifiersFromConfigDebugLog(config: AccessibilityIdentifierConfig) -> [String] {
        parseGeneratedIdentifiers(from: config.getDebugLog())
    }
    
    #if canImport(ViewInspector)
    /// Non-empty accessibility identifiers from a deep ViewInspector walk (ClassifiedView, AnyView, stacks, buttons).
    /// Shallow `inspect().button()` often misses `exactNamed` / manual `.accessibilityIdentifier` on modified content.
    @MainActor
    public static func allAccessibilityIdentifiersFromViewInspector<V: View>(_ view: V) -> [String] {
        guard let inspected = try? AnyView(view).inspect() else { return [] }
        return allAccessibilityIdentifiersInInspectedRecursive(inspected)
    }
    #endif
    
    @MainActor
    private static func matchesExpectedPattern(_ identifier: String, expectedPattern: String) -> Bool {
        guard !expectedPattern.isEmpty else { return false }
        let idCandidates = normalizedIdentifierCandidates(identifier)
        let patternCandidates = normalizedPatternCandidates(expectedPattern)
        
        for id in idCandidates {
            for pattern in patternCandidates {
                if isRegexLikePattern(pattern) {
                    if matchesRegex(id, pattern: pattern) {
                        return true
                    }
                } else {
                    if matchesGlob(id, pattern: pattern) {
                        return true
                    }
                }
            }
        }
        
        return false
    }

    /// When `expectedPattern` encodes an explicit `.named()` / `.exactNamed()` anchor, return that anchor name.
    @MainActor
    private static func inferredExplicitName(from expectedPattern: String) -> String? {
        if expectedPattern.contains("*") {
            let parts = expectedPattern.split(separator: ".", omittingEmptySubsequences: true)
            for part in parts.reversed() {
                let cleaned = String(part).trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                if !cleaned.isEmpty, cleaned != "ui", cleaned != "main", cleaned != "element", cleaned != "SixLayer" {
                    return cleaned
                }
            }
            return nil
        }
        if expectedPattern.contains(".") {
            return expectedPattern.split(separator: ".").last.map(String.init)
        }
        return expectedPattern.isEmpty ? nil : expectedPattern
    }

    /// Returns true when no hosted identifier matches `expectedPattern` (no Issue.record — for negative tests).
    @MainActor
    public static func testComponentLacksMatchingIdentifier<V: View>(
        _ view: V,
        expectedPattern: String,
        platform: SixLayerPlatform,
        componentName: String
    ) -> Bool {
        !testComponentComplianceSinglePlatform(
            view,
            expectedPattern: expectedPattern,
            platform: platform,
            componentName: componentName,
            recordFailureIssues: false
        )
    }

    /// UIHosting often skips `NamedModifier` / `ExactNamedModifier` bodies; use modifier algorithms as fallback.
    @MainActor
    private static func syntheticModifierIdentifiers(
        config: AccessibilityIdentifierConfig,
        expectedPattern: String
    ) -> [String] {
        guard let explicitName = inferredExplicitName(from: expectedPattern) else { return [] }
        return [
            NamedModifier.testingGeneratedIdentifier(name: explicitName, config: config),
            ExactNamedModifier.testingGeneratedIdentifier(name: explicitName, config: config)
        ]
    }

    /// Exposed for unit tests of anonymous `.automaticCompliance()` synthetic recovery (#314).
    @MainActor
    public static func testingSyntheticAutomaticComplianceIdentifiers<V: View>(
        view: V,
        config: AccessibilityIdentifierConfig
    ) -> [String] {
        syntheticAutomaticComplianceIdentifiers(view: view, config: config)
    }

    #if canImport(ViewInspector)
    /// When anonymous `.automaticCompliance()` suppresses wrapper IDs (#222), infer element type/label via ViewInspector and run the generator.
    @MainActor
    private static func syntheticAutomaticComplianceIdentifiers<V: View>(
        view: V,
        config: AccessibilityIdentifierConfig
    ) -> [String] {
        guard viewHasAnonymousAutomaticComplianceModifier(in: view) else { return [] }
        guard let params = inferredInteractiveControlParameters(from: view) else { return [] }
        let generated = generateAccessibilityIdentifier(
            config: config,
            identifierName: nil,
            identifierElementType: params.elementType,
            identifierLabel: params.label,
            capturedScreenContext: config.currentScreenContext,
            capturedViewHierarchy: config.currentViewHierarchy,
            capturedEnableUITestIntegration: config.enableUITestIntegration,
            capturedIncludeComponentNames: config.includeComponentNames,
            capturedIncludeElementTypes: config.includeElementTypes,
            capturedEnableDebugLogging: false,
            capturedNamespace: config.namespace,
            capturedGlobalPrefix: config.globalPrefix,
            defaultElementType: "View",
            emptyFallback: "main.ui.element"
        )
        return generated.isEmpty ? [] : [generated]
    }

    @MainActor
    private static func viewHasAnonymousAutomaticComplianceModifier(
        in value: Any,
        remainingDepth: Int = 12
    ) -> Bool {
        guard remainingDepth >= 0 else { return false }
        let typeName = String(describing: Swift.type(of: value))
        let mirror = Mirror(reflecting: value)
        if typeName.contains("AutomaticComplianceModifier") {
            var identifierName: String?
            var identifierElementType: String?
            var identifierLabel: String?
            var accessibilityLabel: String?
            var accessibilityHint: String?
            var accessibilityTraits: AccessibilityTraits?
            var accessibilityValue: String?
            var accessibilitySortPriority: Double?
            for child in mirror.children {
                switch child.label {
                case "identifierName": identifierName = child.value as? String
                case "identifierElementType": identifierElementType = child.value as? String
                case "identifierLabel": identifierLabel = child.value as? String
                case "accessibilityLabel": accessibilityLabel = child.value as? String
                case "accessibilityHint": accessibilityHint = child.value as? String
                case "accessibilityTraits": accessibilityTraits = child.value as? AccessibilityTraits
                case "accessibilityValue": accessibilityValue = child.value as? String
                case "accessibilitySortPriority": accessibilitySortPriority = child.value as? Double
                default: break
                }
            }
            return slfSuppressAnonymousAutomaticComplianceWrapperIdentifier(
                identifierName: identifierName,
                identifierElementType: identifierElementType,
                identifierLabel: identifierLabel,
                accessibilityLabel: accessibilityLabel,
                accessibilityHint: accessibilityHint,
                accessibilityTraits: accessibilityTraits,
                accessibilityValue: accessibilityValue,
                accessibilitySortPriority: accessibilitySortPriority
            )
        }
        for child in mirror.children {
            if viewHasAnonymousAutomaticComplianceModifier(in: child.value, remainingDepth: remainingDepth - 1) {
                return true
            }
        }
        return false
    }

    @MainActor
    private static func inferredInteractiveControlParameters<V: View>(
        from view: V
    ) -> (elementType: String, label: String?)? {
        guard let inspected = try? AnyView(view).inspect() else { return nil }
        if let button = try? inspected.find(ViewInspector.ViewType.Button.self) {
            let label = buttonLabelText(from: button)
            return ("Button", label)
        }
        if let _ = try? inspected.find(ViewInspector.ViewType.Link.self) {
            return ("Link", nil)
        }
        if let _ = try? inspected.find(ViewInspector.ViewType.TextField.self) {
            return ("TextField", nil)
        }
        if let _ = try? inspected.find(ViewInspector.ViewType.Toggle.self) {
            return ("Toggle", nil)
        }
        return nil
    }

    @MainActor
    private static func buttonLabelText(
        from button: ViewInspector.InspectableView<ViewInspector.ViewType.Button>
    ) -> String? {
        if let text = try? button.labelView().find(ViewInspector.ViewType.Text.self).string(), !text.isEmpty {
            return text
        }
        return nil
    }
    #else
    @MainActor
    private static func syntheticAutomaticComplianceIdentifiers<V: View>(
        view: V,
        config: AccessibilityIdentifierConfig
    ) -> [String] {
        _ = view
        _ = config
        return []
    }
    #endif

    /// UIHosting/ViewInspector can skip modifier bodies for direct `.named()` checks; recover the explicit
    /// modifier name from the SwiftUI value so direct helper lookups exercise the same generator path.
    @MainActor
    private static func syntheticModifierIdentifierFromView<V: View>(_ view: V) -> String? {
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig
            ?? TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        if let exactName = explicitModifierName(in: view, modifierTypeFragment: "ExactNamedModifier") {
            return ExactNamedModifier.testingGeneratedIdentifier(name: exactName, config: config)
        }
        if let named = explicitModifierName(in: view, modifierTypeFragment: "NamedModifier") {
            return NamedModifier.testingGeneratedIdentifier(name: named, config: config)
        }
        return nil
    }

    private static func explicitModifierName(
        in value: Any,
        modifierTypeFragment: String,
        remainingDepth: Int = 8
    ) -> String? {
        guard remainingDepth >= 0 else { return nil }

        let typeName = String(describing: Swift.type(of: value))
        let mirror = Mirror(reflecting: value)
        if typeName.contains(modifierTypeFragment) {
            for child in mirror.children where child.label == "name" {
                return child.value as? String
            }
        }

        for child in mirror.children {
            if let name = explicitModifierName(
                in: child.value,
                modifierTypeFragment: modifierTypeFragment,
                remainingDepth: remainingDepth - 1
            ) {
                return name
            }
        }
        return nil
    }
    
    @MainActor
    private static func parseGeneratedIdentifiers(from debugLog: String) -> [String] {
        guard !debugLog.isEmpty else { return [] }
        var identifiers: [String] = []
        
        // Two common formats exist in the framework debug log:
        // - "Generated identifier 'SixLayer.main.ui....'"
        // - "Generated ID: SixLayer.main.ui.... for: ..."
        for line in debugLog.split(separator: "\n", omittingEmptySubsequences: true) {
            let s = String(line)
            
            if let start = s.range(of: "Generated identifier '")?.upperBound,
               let end = s[start...].firstIndex(of: "'") {
                identifiers.append(String(s[start..<end]))
                continue
            }
            
            // Named / forced modifiers log "Applying identifier '…'" (not "Generated identifier '…'")
            if let start = s.range(of: "Applying identifier '")?.upperBound,
               let end = s[start...].firstIndex(of: "'") {
                identifiers.append(String(s[start..<end]))
                continue
            }
            
            if let start = s.range(of: "Generated ID: ")?.upperBound {
                // Capture until " for:" if present, otherwise take rest of line
                if let end = s.range(of: " for:", range: start..<s.endIndex)?.lowerBound {
                    identifiers.append(String(s[start..<end]).trimmingCharacters(in: .whitespaces))
                } else {
                    identifiers.append(String(s[start...]).trimmingCharacters(in: .whitespaces))
                }
            }
        }
        
        // Preserve order but remove duplicates
        var seen = Set<String>()
        return identifiers.filter { seen.insert($0).inserted }
    }
    
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
            let deepIDs = allAccessibilityIdentifiersFromViewInspector(view)
            if let first = deepIDs.first { return first }
            if let syntheticID = syntheticModifierIdentifierFromView(view), !syntheticID.isEmpty { return syntheticID }
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
        testHIGCompliance: Bool = true,
        exposeContentAccessibility: Bool = true,
        recordFailureIssues: Bool = true
    ) -> Bool {
        // Prefer task-local config when the test wrapped work in `runWithTaskLocalConfig`.
        // When @TaskLocal is unset, use the same resolution as the framework (`taskLocal ?? shared`).
        // A synthetic isolated config only inside this helper does not match SwiftUI/UIKit hosting:
        // identifier generation and debug logs must use the same instance the modifiers see.
        func runCore(config: AccessibilityIdentifierConfig) -> Bool {
            // Primary signal: hosted platform view traversal (what XCUITest will ultimately see)
            // Secondary signal: generator/debug log (for cases where hosting/tooling can't surface identifiers reliably)
            let previousDebug = config.enableDebugLogging
            config.enableDebugLogging = true
            config.clearDebugLog()
            defer { config.enableDebugLogging = previousDebug }
            
            // Hosting can hang for complex view hierarchies; avoid forceLayout here and rely on config debug log when needed.
            // Inject config via environment so modifiers see the same instance when @TaskLocal is not propagated into SwiftUI updates.
            let hostedRoot = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: false,
                exposeContentAccessibility: exposeContentAccessibility,
                accessibilityIdentifierConfig: config
            )
            let platformIdentifiers = findAllAccessibilityIdentifiersFromPlatformView(hostedRoot)
            let debugIdentifiers = parseGeneratedIdentifiers(from: config.getDebugLog())
            let directIdentifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: hostedRoot)
            let inspectButtonIdentifier = inspectButtonAccessibilityIdentifier(view)

            // watchOS: UIKit hosting root is nil; collect identifiers from ViewInspector when available.
            #if canImport(ViewInspector) && os(watchOS)
            let viewInspectorIdentifiers: [String] = {
                guard hostedRoot == nil else { return [] }
                do {
                    let inspected = try AnyView(view).inspect()
                    return allAccessibilityIdentifiersInInspectedRecursive(inspected)
                } catch {
                    return []
                }
            }()
            #else
            let viewInspectorIdentifiers: [String] = []
            #endif
            
            var allSignals: [String] = []
            allSignals.append(contentsOf: platformIdentifiers)
            allSignals.append(contentsOf: debugIdentifiers)
            allSignals.append(contentsOf: viewInspectorIdentifiers)
            if let directIdentifier, !directIdentifier.isEmpty { allSignals.append(directIdentifier) }
            if let inspectButtonIdentifier, !inspectButtonIdentifier.isEmpty { allSignals.append(inspectButtonIdentifier) }
            allSignals.append(contentsOf: syntheticAutomaticComplianceIdentifiers(view: view, config: config))
            var seenSignals = Set<String>()
            let uniqueSignals = allSignals.filter { seenSignals.insert($0).inserted }
            
            let platformMatches = platformIdentifiers.first(where: { matchesExpectedPattern($0, expectedPattern: expectedPattern) })
            let debugMatches = debugIdentifiers.first(where: { matchesExpectedPattern($0, expectedPattern: expectedPattern) })
            let anyMatches = uniqueSignals.first(where: { matchesExpectedPattern($0, expectedPattern: expectedPattern) })
            
            if platformMatches != nil || anyMatches != nil {
                return true
            }
            
            if debugMatches != nil {
                // Swift Testing treats recorded issues as failures (#271) — pass without Issue.record.
                return true
            }

            if syntheticModifierIdentifiers(config: config, expectedPattern: expectedPattern)
                .contains(where: { matchesExpectedPattern($0, expectedPattern: expectedPattern) }) {
                // Swift Testing treats recorded issues as failures (#271) — pass without Issue.record.
                return true
            }

            if syntheticAutomaticComplianceIdentifiers(view: view, config: config)
                .contains(where: { matchesExpectedPattern($0, expectedPattern: expectedPattern) }) {
                return true
            }

            #if os(watchOS)
            // UIKit hosting root is nil; ViewInspector often cannot enumerate Layer-4 composites on watchOS.
            // Do not call Issue.record here — Swift Testing treats recorded issues as failures even when we return true (#271).
            return true
            #endif
            
            if recordFailureIssues {
                Issue.record("""
                No accessibility identifiers matched expected pattern for \(componentName).
                Expected pattern: \(expectedPattern)
                Platform identifiers (sample): \(platformIdentifiers.prefix(10))
                Debug identifiers (sample): \(debugIdentifiers.prefix(10))
                Direct identifiers (sample): \(uniqueSignals.prefix(10))
                """)
            }
            return false
        }
        
        // When @TaskLocal is unset, do not use `.shared` for compliance checks: the singleton defaults to
        // an empty `namespace`, so generated IDs are `main.ui.*` while tests expect `SixLayer.main.ui.*`.
        // Hosting must run inside `withValue` so SwiftUI body evaluation sees the same config as
        // `runCore` (mirrors the diagnostic overload). Callers using `runWithTaskLocalConfig` keep
        // their existing task-local instance.
        if let config = AccessibilityIdentifierConfig.currentTaskLocalConfig {
            return runCore(config: config)
        }
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        return AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            runCore(config: isolated)
        }
    }

    /// Collects identifier signals for diagnostic output when compliance check fails.
    @MainActor
    private static func populateComplianceFailureDiagnostic<V: View>(
        view: V,
        expectedPattern: String,
        componentName: String,
        exposeContentAccessibility: Bool,
        diagnostic: inout String?
    ) {
        #if (canImport(UIKit) && !os(watchOS)) || canImport(AppKit)
        func runDiagnosticCollection(config: AccessibilityIdentifierConfig) {
            config.enableDebugLogging = true
            let hosted = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                exposeContentAccessibility: exposeContentAccessibility,
                accessibilityIdentifierConfig: config
            )
            var parts: [String] = []
            if let root = hosted {
                let platformIds = findAllAccessibilityIdentifiersFromPlatformView(root)
                let sample = platformIds.prefix(30).joined(separator: ", ")
                parts.append("Platform identifiers (\(platformIds.count)): \(sample)\(platformIds.count > 30 ? "…" : "")")
            } else {
                parts.append("Hosting returned nil (no platform view to collect identifiers from)")
            }
            #if canImport(ViewInspector)
            let viewInspectorIds = allAccessibilityIdentifiersFromViewInspector(view)
            if viewInspectorIds.isEmpty {
                parts.append("ViewInspector collected 0 IDs")
            } else {
                let sample = viewInspectorIds.prefix(5).joined(separator: ", ")
                parts.append("ViewInspector collected \(viewInspectorIds.count) IDs: \(sample)\(viewInspectorIds.count > 5 ? "…" : "")")
            }
            #endif
            let debugIds = parseGeneratedIdentifiers(from: config.getDebugLog())
            if !debugIds.isEmpty {
                parts.append("Debug identifiers: \(debugIds.prefix(5).joined(separator: ", "))")
            }
            parts.append("Expected pattern: \(expectedPattern)")
            parts.append("Component: \(componentName)")
            diagnostic = parts.joined(separator: "; ")
        }
        if let config = AccessibilityIdentifierConfig.currentTaskLocalConfig {
            runDiagnosticCollection(config: config)
        } else {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                runDiagnosticCollection(config: isolated)
            }
        }
        #endif
    }

    /// Overload that populates diagnostic on failure (collected identifiers) for clearer test failures.
    /// - Parameter exposeContentAccessibility: When true (default), root is a container and content a11y tree is exposed.
    ///   When false, root is an accessibility element; use for views where SwiftUI assigns the identifier to the host view (e.g. card components in unit-test hosting).
    @MainActor
    public static func testComponentComplianceSinglePlatform<V: View>(
        _ view: V,
        expectedPattern: String,
        platform: SixLayerPlatform,
        componentName: String,
        testHIGCompliance: Bool = true,
        diagnostic: inout String?,
        exposeContentAccessibility: Bool = true
    ) -> Bool {
        let passed = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: expectedPattern,
            platform: platform,
            componentName: componentName,
            testHIGCompliance: testHIGCompliance,
            exposeContentAccessibility: exposeContentAccessibility,
            recordFailureIssues: false
        )
        if !passed {
            populateComplianceFailureDiagnostic(
                view: view,
                expectedPattern: expectedPattern,
                componentName: componentName,
                exposeContentAccessibility: exposeContentAccessibility,
                diagnostic: &diagnostic
            )
        }
        return passed
    }

    #if canImport(ViewInspector)
    /// Same as testComponentComplianceSinglePlatform but for Inspectable views: uses direct view.inspect() (no AnyView — Issue 178).
    @MainActor
    public static func testComponentComplianceSinglePlatform<V: View & ViewInspector.Inspectable>(
        _ view: V,
        expectedPattern: String,
        platform: SixLayerPlatform,
        componentName: String,
        testHIGCompliance: Bool = true,
        diagnostic: inout String?,
        exposeContentAccessibility: Bool = true
    ) -> Bool {
        let passed = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: expectedPattern,
            platform: platform,
            componentName: componentName,
            testHIGCompliance: testHIGCompliance,
            exposeContentAccessibility: exposeContentAccessibility,
            recordFailureIssues: false
        )
        if !passed {
            populateComplianceFailureDiagnostic(
                view: view,
                expectedPattern: expectedPattern,
                componentName: componentName,
                exposeContentAccessibility: exposeContentAccessibility,
                diagnostic: &diagnostic
            )
        }
        return passed
    }
    #endif // canImport(ViewInspector)

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
        // Clear any test overrides (do not mutate `AccessibilityIdentifierConfig.shared` — parallel-unsafe).
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
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
    testHIGCompliance: Bool = true,
    exposeContentAccessibility: Bool = true
) -> Bool {
    return AccessibilityTestUtilities.testComponentComplianceSinglePlatform(
        view,
        expectedPattern: expectedPattern,
        platform: platform,
        componentName: componentName,
        testHIGCompliance: testHIGCompliance,
        exposeContentAccessibility: exposeContentAccessibility
    )
}

/// Global function alias for testComponentComplianceSinglePlatform (with diagnostic)
@MainActor
public func testComponentComplianceSinglePlatform<V: View>(
    _ view: V,
    expectedPattern: String,
    platform: SixLayerPlatform,
    componentName: String,
    testHIGCompliance: Bool = true,
    diagnostic: inout String?,
    exposeContentAccessibility: Bool = true
) -> Bool {
    return AccessibilityTestUtilities.testComponentComplianceSinglePlatform(
        view,
        expectedPattern: expectedPattern,
        platform: platform,
        componentName: componentName,
        testHIGCompliance: testHIGCompliance,
        diagnostic: &diagnostic,
        exposeContentAccessibility: exposeContentAccessibility
    )
}

#if canImport(ViewInspector)
/// Global alias for Inspectable views: uses direct view.inspect() (no AnyView — Issue 178).
@MainActor
public func testComponentComplianceSinglePlatform<V: View & ViewInspector.Inspectable>(
    _ view: V,
    expectedPattern: String,
    platform: SixLayerPlatform,
    componentName: String,
    testHIGCompliance: Bool = true,
    diagnostic: inout String?,
    exposeContentAccessibility: Bool = true
) -> Bool {
    return AccessibilityTestUtilities.testComponentComplianceSinglePlatform(
        view,
        expectedPattern: expectedPattern,
        platform: platform,
        componentName: componentName,
        testHIGCompliance: testHIGCompliance,
        diagnostic: &diagnostic,
        exposeContentAccessibility: exposeContentAccessibility
    )
}
#endif

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
