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

// MARK: - Type Aliases

/// Type alias for ViewInspector's InspectableView
/// ViewInspector's inspect() returns InspectableView<ViewType.View<Self>>, which we type-erase for convenience
public typealias InspectedView = InspectableView<ViewType.View<AnyView>>

// MARK: - View Extensions

extension View {
    /// Safe, non-throwing inspection of a view
    /// Returns nil if inspection fails (instead of throwing)
    @MainActor
    public func tryInspect() -> InspectedView? {
        do {
            // Type-erase to AnyView to work around type constraints
            let anyView = AnyView(self)
            return try anyView.inspect()
        } catch {
            return nil
        }
    }
    
    /// Throwing inspection of a view
    @MainActor
    public func inspectView() throws -> InspectedView {
        // Type-erase to AnyView to work around type constraints
        let anyView = AnyView(self)
        return try anyView.inspect()
    }
}

// MARK: - InspectedView Extensions

extension InspectedView {
    /// Get accessibility identifier from a view using ViewInspector
    /// Returns empty string if not found or if inspection fails
    public func sixLayerAccessibilityIdentifier() throws -> String {
        // Try to find accessibility identifier
        // This is a simplified implementation - actual implementation would search view hierarchy
        return try accessibilityIdentifier() ?? ""
    }
    
    /// Try to find a view of a specific type
    /// Returns nil if not found (instead of throwing)
    public func sixLayerTryFind<T>(_ type: T.Type) -> T? where T: InspectedView {
        do {
            return try find(type)
        } catch {
            return nil
        }
    }
    
    /// Find all views of a specific type (non-throwing)
    /// Returns empty array if none found or if inspection fails
    public func sixLayerFindAll<T>(_ type: T.Type) -> [T] where T: InspectedView {
        do {
            return try findAll(type)
        } catch {
            return []
        }
    }
    
    /// Find Text view
    public func sixLayerText() throws -> InspectableView<ViewType.Text> {
        return try find(ViewType.Text.self)
    }
    
    /// Get string from Text view
    public func sixLayerString() throws -> String {
        return try string()
    }
    
    /// Find Label view
    public func sixLayerLabelView() throws -> InspectableView<ViewType.Label<Text, Text>> {
        return try find(ViewType.Label<Text, Text>.self)
    }
    
    /// Tap a button
    public func sixLayerTap() throws {
        try tap()
    }
    
    /// Find AnyView
    public func sixLayerAnyView() throws -> InspectableView<ViewType.AnyView> {
        return try find(ViewType.AnyView.self)
    }
}

// MARK: - Helper Functions

/// Execute code with an inspected view (non-throwing)
@MainActor
public func withInspectedView<V: View, T>(
    _ view: V,
    body: (InspectedView) -> T
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
    body: (InspectedView) throws -> T
) throws -> T {
    let inspected = try view.inspectView()
    return try body(inspected)
}
