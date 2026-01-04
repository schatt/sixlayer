//
//  ViewInspectorWrapper.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Centralized wrapper for ViewInspector APIs to handle cross-platform compatibility
//  and provide safe, non-throwing access to ViewInspector functionality
//

import SwiftUI
import ViewInspector
@testable import SixLayerFramework

// MARK: - Helper Functions for Common Patterns

/// Safely inspect a view and execute a throwing closure
/// Throws when ViewInspector cannot inspect the view
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Safely inspect a view and execute a closure, returning nil on failure
/// This is the non-throwing version that returns nil when inspection fails
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (ViewInspector.InspectableView) -> R?
) -> R? {
    guard let inspected = try? view.inspect() else {
        return nil
    }
    return perform(inspected)
}

// MARK: - View Extension

extension View where Self: ViewInspector.KnownViewType {
    /// Try to inspect a view, returning nil if inspection fails
    @MainActor
    func tryInspect() -> InspectableView<Self>? {
        return try? self.inspect()
    }
}