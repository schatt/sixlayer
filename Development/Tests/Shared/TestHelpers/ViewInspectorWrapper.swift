//
//  ViewInspectorWrapper.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Centralized wrapper for ViewInspector APIs to handle cross-platform compatibility
//  and provide safe, non-throwing access to ViewInspector functionality
//

import SwiftUI
import Foundation
import ViewInspector
@testable import SixLayerFramework

// MARK: - Helper Functions for Common Patterns

/// Safely inspect a view and execute a throwing closure
/// Throws when ViewInspector cannot inspect the view
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (any ViewInspector.InspectableView) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Safely inspect a view and execute a closure, returning nil on failure
/// This is the non-throwing version that returns nil when inspection fails
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (any ViewInspector.InspectableView) -> R?
) -> R? {
    guard let inspected = try? view.inspect() else {
        return nil
    }
    return perform(inspected)
}
