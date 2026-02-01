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
import ViewInspector
@testable import SixLayerFramework

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

// MARK: - Inspection from View instances
// Prefer inspectView(view) over a View extension; ViewInspector’s Inspectable requirement
// on Self in extension View where Self: KnownViewType caused “Self does not conform to Inspectable”.
// Issue 178.