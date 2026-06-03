//
//  ViewInspectorWrapper.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Centralized wrapper for ViewInspector APIs to handle cross-platform compatibility
//  and provide safe, non-throwing access to ViewInspector functionality.
//  All inspection uses the view directly (no AnyView wrap) so ViewInspector can traverse — Issue 178.
//

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector

// MARK: - Canonical inspection (DRY) — direct inspection only, no AnyView

/// Inspect a view directly so ViewInspector traverses the real hierarchy.
/// Call only with views whose type conforms to ViewInspector.Inspectable.
@MainActor
public func inspectView<V: View & ViewInspector.Inspectable>(_ view: V) -> ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>? {
    try? view.inspect()
}

/// Safely inspect a view and run a throwing closure on the inspected hierarchy.
/// Use only with views whose type conforms to ViewInspector.Inspectable.
@MainActor
public func withInspectedViewThrowing<V: View & ViewInspector.Inspectable, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Safely inspect a view and run a closure, returning nil if inspection fails.
/// Use only with views whose type conforms to ViewInspector.Inspectable.
@MainActor
public func withInspectedView<V: View & ViewInspector.Inspectable, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) -> R?
) -> R? {
    guard let inspected = try? view.inspect() else { return nil }
    return perform(inspected)
}

// MARK: - Type-erased opt-in (non-Inspectable view types)

/// Inspect via AnyView when the concrete type does not conform to Inspectable.
/// ViewInspector returns InspectableView<ViewType.ClassifiedView> for AnyView.inspect().
@MainActor
public func withInspectedViewThrowing<R>(
    _ view: AnyView,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Run a closure with an inspected AnyView when the concrete type does not conform to Inspectable.
@MainActor
public func withInspectedView<R>(
    _ view: AnyView,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) -> R?
) -> R? {
    guard let inspected = try? view.inspect() else { return nil }
    return perform(inspected)
}

// MARK: - Type-erased with unwrapped content (for .vStack() etc. — Issue 178)

/// Like withInspectedViewThrowing(AnyView) but passes the unwrapped inner view so .vStack() works.
@MainActor
public func withInspectedViewThrowingUnwrapped<R>(
    _ view: AnyView,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    let inner = try inspected.anyView()
    return try perform(inner)
}

/// Like withInspectedView(AnyView) but passes the unwrapped inner view so .vStack() works.
@MainActor
public func withInspectedViewUnwrapped<R>(
    _ view: AnyView,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) -> R?
) -> R? {
    guard let inspected = try? view.inspect(), let inner = try? inspected.anyView() else { return nil }
    return perform(inner)
}

/// Convenience: inspect any view and pass unwrapped content so .vStack() etc. work.
@MainActor
public func withInspectedViewThrowingUnwrapped<R>(
    _ view: some View,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) throws -> R
) throws -> R {
    try withInspectedViewThrowingUnwrapped(AnyView(view), perform: perform)
}

/// Convenience: inspect any view and pass unwrapped content so .vStack() etc. work.
@MainActor
public func withInspectedViewUnwrapped<R>(
    _ view: some View,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) -> R?
) -> R? {
    withInspectedViewUnwrapped(AnyView(view), perform: perform)
}

/// Convenience: inspect any view via AnyView when the type does not conform to Inspectable.
@MainActor
public func withInspectedViewThrowing<R>(
    _ view: some View,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) throws -> R
) throws -> R {
    try withInspectedViewThrowing(AnyView(view), perform: perform)
}

/// Convenience: inspect any view via AnyView when the type does not conform to Inspectable.
@MainActor
public func withInspectedView<R>(
    _ view: some View,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) -> R?
) -> R? {
    withInspectedView(AnyView(view), perform: perform)
}

// MARK: - Hierarchy traversal (Issue 178)

/// Thrown when no VStack is found in the inspected hierarchy.
public struct NoVStackInHierarchy: Error {}

/// When the root is InspectableView<ViewType.ClassifiedView>, get the best VStack in the hierarchy.
/// When `minChildren` is set, prefers the first VStack with at least that many direct children.
@MainActor
public func firstVStackInHierarchy(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    let list = inspected.findAll(ViewInspector.ViewType.VStack.self)
    guard !list.isEmpty else { throw NoVStackInHierarchy() }
    if let min = minChildren, let match = list.first(where: { $0.count >= min }) {
        return match
    }
    guard let first = list.first else { throw NoVStackInHierarchy() }
    return first
}

/// Legacy overload without minChildren preference.
@MainActor
public func firstVStackInHierarchy(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    try firstVStackInHierarchy(inspected, minChildren: nil)
}

/// When the root is InspectableView<ViewType.AnyView>, get the best VStack in the hierarchy.
@MainActor
public func firstVStackInHierarchy(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    let list = inspected.findAll(ViewInspector.ViewType.VStack.self)
    guard !list.isEmpty else { throw NoVStackInHierarchy() }
    if let min = minChildren, let match = list.first(where: { $0.count >= min }) {
        return match
    }
    guard let first = list.first else { throw NoVStackInHierarchy() }
    return first
}

@MainActor
public func firstVStackInHierarchy(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    try firstVStackInHierarchy(inspected, minChildren: nil)
}

/// When the root is InspectableView<ViewType.View<V>>, get the best VStack in the hierarchy.
@MainActor
public func firstVStackInHierarchy<V: View & ViewInspector.Inspectable>(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    let list = inspected.findAll(ViewInspector.ViewType.VStack.self)
    guard !list.isEmpty else { throw NoVStackInHierarchy() }
    if let min = minChildren, let match = list.first(where: { $0.count >= min }) {
        return match
    }
    guard let first = list.first else { throw NoVStackInHierarchy() }
    return first
}

@MainActor
public func firstVStackInHierarchy<V: View & ViewInspector.Inspectable>(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    try firstVStackInHierarchy(inspected, minChildren: nil)
}

/// Resolve a VStack from a view, preferring direct Inspectable inspection then AnyView fallback (#242).
@MainActor
public func firstVStackInView<V: View & ViewInspector.Inspectable>(
    _ view: V,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> {
    if let inspected = try? view.inspect(),
       let vStack = try? firstVStackInHierarchy(inspected, minChildren: minChildren) {
        return vStack
    }
    let anyInspected = try AnyView(view).inspect()
    return try firstVStackInHierarchy(anyInspected, minChildren: minChildren)
}

/// Collect `viewType` matches after unwrapping AnyView boundaries (Issue 178).
@MainActor
public func findAllInViewHierarchy<V: View & ViewInspector.Inspectable, T: ViewInspector.KnownViewType>(
    _ view: V,
    _ viewType: T.Type
) -> [ViewInspector.InspectableView<T>] {
    guard let inspected = try? view.inspect() else {
        return findAllInViewHierarchyErased(AnyView(view), viewType)
    }
    var results = inspected.findAll(viewType)
    if results.isEmpty, let vStack = try? firstVStackInHierarchy(inspected) {
        results = vStack.findAll(viewType)
    }
    if results.isEmpty, let scroll = try? inspected.scrollView() {
        results = scroll.findAll(viewType)
    }
    if results.isEmpty {
        results = findAllInViewHierarchyErased(AnyView(view), viewType)
    }
    return results
}

/// Collect `viewType` matches after unwrapping AnyView boundaries (Issue 178).
@MainActor
public func findAllInViewHierarchy<T: ViewInspector.KnownViewType>(
    _ view: some View,
    _ viewType: T.Type,
    maxAnyViewUnwrapDepth: Int = 12
) -> [ViewInspector.InspectableView<T>] {
    findAllInViewHierarchyErased(AnyView(view), viewType, maxAnyViewUnwrapDepth: maxAnyViewUnwrapDepth)
}

@MainActor
private func findAllInViewHierarchyErased<T: ViewInspector.KnownViewType>(
    _ view: AnyView,
    _ viewType: T.Type,
    maxAnyViewUnwrapDepth: Int = 12
) -> [ViewInspector.InspectableView<T>] {
    guard let inspected = try? view.inspect() else { return [] }
    var results: [ViewInspector.InspectableView<T>] = []

    func merge(_ batch: [ViewInspector.InspectableView<T>]) {
        results.append(contentsOf: batch)
    }

    func searchAnyViewRoot(_ root: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>) {
        merge(root.findAll(viewType))
        if let scroll = try? root.scrollView() {
            merge(scroll.findAll(viewType))
        }
        if let lazy = try? root.lazyVStack() {
            merge(lazy.findAll(viewType))
        }
        if let vStack = try? root.vStack() {
            merge(vStack.findAll(viewType))
        }
    }

    merge(inspected.findAll(viewType))
    if let vStack = try? firstVStackInHierarchy(inspected) {
        merge(vStack.findAll(viewType))
    }
    if let scroll = try? inspected.scrollView() {
        merge(scroll.findAll(viewType))
    }

    var anyRoot: ViewInspector.InspectableView<ViewInspector.ViewType.AnyView>? = try? inspected.anyView()
    var depth = 0
    while depth < maxAnyViewUnwrapDepth, let root = anyRoot {
        searchAnyViewRoot(root)
        anyRoot = try? root.anyView()
        depth += 1
    }

    return results
}

// MARK: - Inspection from View instances
// Prefer inspectView(view) over a View extension; ViewInspector’s Inspectable requirement
// on Self in extension View where Self: KnownViewType caused “Self does not conform to Inspectable”.
// Issue 178.

#endif // canImport(ViewInspector)