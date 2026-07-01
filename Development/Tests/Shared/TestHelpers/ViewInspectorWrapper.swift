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
/// Call with a concrete view type for direct hierarchy inspection.
@MainActor
public func inspectView<V: View>(_ view: V) -> ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>? where V != AnyView {
    try? view.inspect().view(V.self)
}

/// Safely inspect a view and run a throwing closure on the inspected hierarchy.
/// Use with a concrete view type for direct hierarchy inspection.
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) throws -> R
) throws -> R where V != AnyView {
    let inspected = try view.inspect().view(V.self)
    return try perform(inspected)
}

/// Safely inspect a view and run a closure, returning nil if inspection fails.
/// Use with a concrete view type for direct hierarchy inspection.
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) -> R?
) -> R? where V != AnyView {
    guard let inspected = try? view.inspect().view(V.self) else { return nil }
    return perform(inspected)
}

// MARK: - Type-erased fallbacks (AnyView / opaque some View)

/// Inspect via AnyView when direct typed inspection is impractical.
/// ViewInspector returns InspectableView<ViewType.ClassifiedView> for AnyView.inspect().
@MainActor
public func withInspectedViewThrowing<R>(
    _ view: AnyView,
    perform: (ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Run a closure with an inspected AnyView when direct typed inspection is impractical.
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
public func firstVStackInHierarchy<V: View>(
    _ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> where V != AnyView {
    let list = inspected.findAll(ViewInspector.ViewType.VStack.self)
    guard !list.isEmpty else { throw NoVStackInHierarchy() }
    if let min = minChildren, let match = list.first(where: { $0.count >= min }) {
        return match
    }
    guard let first = list.first else { throw NoVStackInHierarchy() }
    return first
}

@MainActor
public func firstVStackInHierarchy<V: View>(_ inspected: ViewInspector.InspectableView<ViewInspector.ViewType.View<V>>) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> where V != AnyView {
    try firstVStackInHierarchy(inspected, minChildren: nil)
}

/// Resolve a VStack from a view, preferring direct typed inspection then AnyView fallback (#242).
@MainActor
public func firstVStackInView<V: View>(
    _ view: V,
    minChildren: Int? = nil
) throws -> ViewInspector.InspectableView<ViewInspector.ViewType.VStack> where V != AnyView {
    if let inspected = try? view.inspect().view(V.self),
       let vStack = try? firstVStackInHierarchy(inspected, minChildren: minChildren) {
        return vStack
    }
    let anyInspected = try AnyView(view).inspect()
    return try firstVStackInHierarchy(anyInspected, minChildren: minChildren)
}

// MARK: - Inspection from View instances
// Prefer inspectView(view) over a View extension (Issue 178).

#endif // canImport(ViewInspector)