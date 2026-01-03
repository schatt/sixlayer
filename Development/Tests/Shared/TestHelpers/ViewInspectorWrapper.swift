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

// MARK: - Convenience Extensions

/// Simple extensions to add convenience methods to ViewInspector types
extension ViewInspector.InspectableView {
    func sixLayerFindAll<T>(_ type: T.Type) -> [ViewInspector.InspectableView] {
        return (try? self.findAll(type)) ?? []
    }

    func sixLayerString() throws -> String {
        return try self.string()
    }
}

// MARK: - InspectableView Extension for Common Operations

extension InspectableView {
    /// Safely find a view type, returning nil if not found
    func tryFind<T: SwiftUI.View>(_ type: T.Type) -> InspectableView<ViewType.View<T>>? {
        return try? self.find(type)
    }

    /// Safely find all views of a type, returning empty array if none found
    func tryFindAll<T: SwiftUI.View>(_ type: T.Type) -> [InspectableView<ViewType.View<T>>] {
        return (try? self.findAll(type)) ?? []
    }
}

// MARK: - View Extension for Inspection

extension View {
    /// Safely inspect a view and return the InspectableView
    /// Throws when ViewInspector cannot inspect the view
    @MainActor
    func inspectView() throws -> any ViewInspector.InspectableView {
        return try self.inspect()
    }
}

// MARK: - Helper Functions for Common Patterns

/// Safely inspect a view and execute a throwing closure
/// Throws when ViewInspector cannot inspect the view
/// Uses Inspectable protocol for consistent type across platforms
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (any ViewInspector.InspectableView) throws -> R
) throws -> R {
    let inspected = try view.inspectView()
    return try perform(inspected)
}

/// Safely inspect a view and execute a closure, returning nil on failure
/// This is the non-throwing version that returns nil when inspection fails
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (any ViewInspector.InspectableView) -> R?
) -> R? {
    guard let inspected = try? view.inspectView() else {
        return nil
    }
    return perform(inspected)
}
