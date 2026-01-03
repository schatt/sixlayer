//
//  ViewInspectorWrapper.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Centralized wrapper for ViewInspector APIs to handle cross-platform compatibility
//  and provide safe, non-throwing access to ViewInspector functionality
//

import Foundation
import SwiftUI
import ViewInspector

// MARK: - View Extensions

extension View {
    /// Safe, non-throwing inspection of a view
    /// Returns nil if inspection fails (instead of throwing)
    @MainActor
    public func tryInspect() -> InspectableView<ViewType.View<Self>>? {
        do {
            return try inspect()
        } catch {
            return nil
        }
    }
    
    /// Throwing inspection of a view
    @MainActor
    public func inspectView() throws -> InspectableView<ViewType.View<Self>> {
        return try inspect()
    }
}

// MARK: - InspectableView Extensions

extension InspectableView {
    /// Get accessibility identifier from a view using ViewInspector
    /// Returns empty string if not found or if inspection fails
    public func sixLayerAccessibilityIdentifier() throws -> String {
        // Try to find accessibility identifier
        // This is a simplified implementation - actual implementation would search view hierarchy
        return try accessibilityIdentifier() ?? ""
    }
    
    /// Try to find a view of a specific type
    /// Returns nil if not found (instead of throwing)
    public func sixLayerTryFind<T>(_ type: T.Type) -> T? where T: InspectableView {
        do {
            return try find(type)
        } catch {
            return nil
        }
    }
    
    /// Find all views of a specific type (non-throwing)
    /// Returns empty array if none found or if inspection fails
    public func sixLayerFindAll<T>(_ type: T.Type) -> [T] where T: InspectableView {
        do {
            return try findAll(type)
        } catch {
            return []
        }
    }
}

// MARK: - Helper Functions

/// Execute code with an inspected view (non-throwing)
@MainActor
public func withInspectedView<V: View, T>(
    _ view: V,
    body: (InspectableView<ViewType.View<V>>) -> T
) -> T? {
    guard let inspected = view.tryInspect() else {
        return nil
    }
    return body(inspected)
}

/// Execute code with an inspected view (throwing)
@MainActor
public func withInspectedViewThrowing<V: View, T>(
    _ view: V,
    body: (InspectableView<ViewType.View<V>>) throws -> T
) throws -> T {
    let inspected = try view.inspectView()
    return try body(inspected)
}
