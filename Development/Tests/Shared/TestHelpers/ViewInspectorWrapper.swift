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

// MARK: - Type-Erased Inspectable Protocol

/// Protocol that abstracts ViewInspector's InspectableView
/// This allows the wrapper to return a consistent type regardless of platform
/// Uses prefixed method names to avoid naming conflicts with ViewInspector and prevent infinite recursion
public protocol Inspectable {
    func sixLayerText() throws -> Inspectable
    func sixLayerText(_ index: Int) throws -> Inspectable
    func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable]
    func sixLayerString() throws -> String
}

// MARK: - InspectableView Conformance

extension ViewInspector.InspectableView: Inspectable {
    public func sixLayerText() throws -> Inspectable {
        let result = try self.text()
        return result
    }

    public func sixLayerText(_ index: Int) throws -> Inspectable {
        let result = try self.text(index)
        return result
    }

    public func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable] {
        let results = (try? self.findAll(type)) ?? []
        return results.map { $0 as Inspectable }
    }

    public func sixLayerString() throws -> String {
        return try self.string()
    }
}

// MARK: - View Extension

extension View {
    /// Try to inspect a view, returning nil if inspection fails
    @MainActor
    func tryInspect() -> (any Inspectable)? {
        return try? self.inspect()
    }
}

// MARK: - Helper Functions for Common Patterns

/// Safely inspect a view and execute a throwing closure
/// Throws when ViewInspector cannot inspect the view
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (Inspectable) throws -> R
) throws -> R {
    let inspected = try view.inspect()
    return try perform(inspected)
}

/// Safely inspect a view and execute a closure, returning nil on failure
/// This is the non-throwing version that returns nil when inspection fails
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (Inspectable) -> R?
) -> R? {
    guard let inspected = try? view.inspect() else {
        return nil
    }
    return perform(inspected)
}
