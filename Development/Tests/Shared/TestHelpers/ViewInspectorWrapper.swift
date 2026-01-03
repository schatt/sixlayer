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
    func sixLayerButton() throws -> Inspectable
    func sixLayerText() throws -> Inspectable
    func sixLayerText(_ index: Int) throws -> Inspectable
    func sixLayerAnyView() throws -> Inspectable
    func sixLayerLabelView() throws -> Inspectable
    func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable]
    func sixLayerFind<T>(_ type: T.Type) throws -> Inspectable
    func sixLayerTryFind<T>(_ type: T.Type) -> Inspectable?
    func sixLayerAccessibilityIdentifier() throws -> String
    func sixLayerString() throws -> String
    func sixLayerTap() throws
    var sixLayerCount: Int { get }
}

// MARK: - InspectableView Conformance

extension ViewInspector.InspectableView: Inspectable {
    public func sixLayerButton() throws -> Inspectable {
        // This is a simplified implementation - actual button detection would be more complex
        let result = try self.find(ViewType.Button.self)
        return result
    }

    public func sixLayerText() throws -> Inspectable {
        let result = try self.text()
        return result
    }

    public func sixLayerText(_ index: Int) throws -> Inspectable {
        let result = try self.text(index)
        return result
    }

    public func sixLayerAnyView() throws -> Inspectable {
        let result = try self.anyView()
        return result
    }

    public func sixLayerLabelView() throws -> Inspectable {
        let result = try self.labelView()
        return result
    }

    public func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable] {
        let results = (try? self.findAll(type)) ?? []
        return results.map { $0 as Inspectable }
    }

    public func sixLayerFind<T>(_ type: T.Type) throws -> Inspectable {
        let result = try self.find(type)
        return result
    }

    public func sixLayerTryFind<T>(_ type: T.Type) -> Inspectable? {
        return try? self.find(type)
    }

    public func sixLayerAccessibilityIdentifier() throws -> String {
        return try self.accessibilityIdentifier()
    }

    public func sixLayerString() throws -> String {
        return try self.string()
    }

    public func sixLayerTap() throws {
        try self.tap()
    }

    public var sixLayerCount: Int {
        return self.count
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
