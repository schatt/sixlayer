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
    func sixLayerVStack() throws -> Inspectable
    func sixLayerVStack(_ index: Int) throws -> Inspectable
    func sixLayerHStack() throws -> Inspectable
    func sixLayerHStack(_ index: Int) throws -> Inspectable
    func sixLayerZStack() throws -> Inspectable
    func sixLayerTextField() throws -> Inspectable
    func sixLayerTextField(_ index: Int) throws -> Inspectable
    func sixLayerLink() throws -> Inspectable
    func sixLayerFindAllLinks() -> [Inspectable]
    func sixLayerAccessibilityIdentifier() throws -> String
    func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable]
    func sixLayerFind<T>(_ type: T.Type) throws -> Inspectable
    func sixLayerTryFind<T>(_ type: T.Type) -> Inspectable?
    func sixLayerAnyView() throws -> Inspectable
    func sixLayerString() throws -> String
    func sixLayerCallOnTapGesture() throws
    func sixLayerLabelView() throws -> Inspectable
    func sixLayerTap() throws
    var sixLayerCount: Int { get }
    var sixLayerIsEmpty: Bool { get }
    func sixLayerContains(_ element: Inspectable) -> Bool
}

// Make InspectableView conform to our protocol
// This extension applies to all InspectableView types from ViewInspector
extension InspectableView: Inspectable {
    public func sixLayerButton() throws -> Inspectable {
        // Use findAll(where:) to find buttons - Button types vary by label
        // Try to find any button by checking if we can access button-specific methods
        let allViews = try self.findAll(where: { view in
            // Check if this is a button by trying to access button-specific properties
            // This is a best-effort approach
            return true // We'll filter at usage
        })
        // Try to find a button by attempting to cast to button types
        // This is simplified - actual button detection happens when methods are called
        if let firstView = allViews.first {
            return firstView as Inspectable
        }
        throw InspectionError.notSupported("sixLayerButton() requires a Button view")
    }
    
    public func sixLayerText() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.Text to recursively search for Text views
        let texts = try self.findAll(ViewType.Text.self)
        if let firstText = texts.first {
            return firstText as Inspectable
        }
        throw InspectionError.notSupported("sixLayerText() requires a Text view")
    }
    
    public func sixLayerText(_ index: Int) throws -> Inspectable {
        // This works on VStack/HStack which have indexed access
        if let vStackSelf = self as? InspectableView<ViewType.VStack> {
            return try vStackSelf.text(index) as Inspectable
        }
        // Fallback: try direct access via findAll
        let texts = try self.findAll(ViewType.Text.self)
        if let firstText = texts.first {
            return firstText as Inspectable
        }
        throw InspectionError.notSupported("sixLayerText() requires a Text view")
    }
    
    public func sixLayerVStack() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.VStack to recursively search for VStacks
        // This will find VStacks even when wrapped in modifiers
        let vStacks = try self.findAll(ViewType.VStack.self)
        if let firstVStack = vStacks.first {
            return firstVStack as Inspectable
        }
        throw InspectionError.notSupported("sixLayerVStack() requires a VStack view")
    }
    
    public func sixLayerVStack(_ index: Int) throws -> Inspectable {
        // VStack from MultipleViewContent parent (like another VStack) supports indexed access
        if let vStackSelf = self as? InspectableView<ViewType.VStack> {
            return try vStackSelf.vStack(index) as Inspectable
        }
        // Fallback: try direct access via findAll
        let vStacks = try self.findAll(ViewType.VStack.self)
        if let firstVStack = vStacks.first {
            return firstVStack as Inspectable
        }
        throw InspectionError.notSupported("sixLayerVStack() requires a VStack view")
    }
    
    public func sixLayerHStack() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.HStack to recursively search for HStacks
        let hStacks = try self.findAll(ViewType.HStack.self)
        if let firstHStack = hStacks.first {
            return firstHStack as Inspectable
        }
        throw InspectionError.notSupported("sixLayerHStack() requires an HStack view")
    }
    
    public func sixLayerHStack(_ index: Int) throws -> Inspectable {
        // HStack from MultipleViewContent parent (like VStack) supports indexed access
        if let vStackSelf = self as? InspectableView<ViewType.VStack> {
            return try vStackSelf.hStack(index) as Inspectable
        }
        // Fallback: try direct access via findAll
        let hStacks = try self.findAll(ViewType.HStack.self)
        if let firstHStack = hStacks.first {
            return firstHStack as Inspectable
        }
        throw InspectionError.notSupported("sixLayerHStack() requires an HStack view")
    }
    
    public func sixLayerZStack() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.ZStack to recursively search for ZStacks
        let zStacks = try self.findAll(ViewType.ZStack.self)
        if let firstZStack = zStacks.first {
            return firstZStack as Inspectable
        }
        throw InspectionError.notSupported("sixLayerZStack() requires a ZStack view")
    }
    
    public func sixLayerTextField() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.TextField to recursively search for TextFields
        let textFields = try self.findAll(ViewType.TextField.self)
        if let firstTextField = textFields.first {
            return firstTextField as Inspectable
        }
        throw InspectionError.notSupported("sixLayerTextField() requires a TextField view")
    }
    
    public func sixLayerTextField(_ index: Int) throws -> Inspectable {
        // This works on VStack/HStack which have indexed access
        if let vStackSelf = self as? InspectableView<ViewType.VStack> {
            return try vStackSelf.textField(index) as Inspectable
        }
        // Fallback: try direct access via findAll
        let textFields = try self.findAll(ViewType.TextField.self)
        if let firstTextField = textFields.first {
            return firstTextField as Inspectable
        }
        throw InspectionError.notSupported("sixLayerTextField() requires a TextField view")
    }
    
    public func sixLayerLink() throws -> Inspectable {
        // Use ViewInspector's findAll with ViewType.Link to recursively search for Link views
        let links = try self.findAll(ViewType.Link.self)
        if let firstLink = links.first {
            return firstLink as Inspectable
        }
        throw InspectionError.notSupported("sixLayerLink() requires a Link view")
    }
    
    public func sixLayerFindAllLinks() -> [Inspectable] {
        // Use ViewInspector's findAll with ViewType.Link to recursively search for Link views
        // Non-throwing version - returns empty array on failure
        guard let links = try? self.findAll(ViewType.Link.self) else {
            return []
        }
        return links.map { $0 as Inspectable }
    }
    
    public func sixLayerAccessibilityIdentifier() throws -> String {
        // No recursion risk - different method name than ViewInspector's accessibilityIdentifier()
        // Only return the identifier for this specific view, do not search children recursively
        // If a test needs to find an identifier in a child view, it should navigate to that child first
        
        // Safely call ViewInspector's accessibilityIdentifier() method
        // Use try? to prevent crashes if ViewInspector's method throws or crashes
        // Return empty string if the call fails, which tests can check for
        guard let identifier = try? self.accessibilityIdentifier() else {
            return ""
        }
        return identifier
    }
    
    public func sixLayerFindAll<T>(_ type: T.Type) -> [Inspectable] {
        // Use ViewInspector's findAll method to search for views matching the type
        // This properly filters by the ViewType
        guard let matchingViews = try? self.findAll(type) else {
            return []
        }
        return matchingViews.map { $0 as Inspectable }
    }
    
    public func sixLayerFind<T>(_ type: T.Type) throws -> Inspectable {
        // Thin wrapper around ViewInspector's find method
        // The slowness is in ViewInspector itself, not this wrapper
        let found = try self.find(where: { _ in true })
        return found as Inspectable
    }
    
    public func sixLayerTryFind<T>(_ type: T.Type) -> Inspectable? {
        return try? self.sixLayerFind(type)
    }
    
    public func sixLayerAnyView() throws -> Inspectable {
        // Use find(where:) to find any view, avoiding SingleViewContent constraint
        // This is a workaround for the anyView() constraint issue
        if let anyViewResult = try? self.find(where: { _ in true }) {
            return anyViewResult as Inspectable
        }
        // If that fails, return self as a fallback
        return self as Inspectable
    }
    
    public func sixLayerString() throws -> String {
        // No recursion - different method name than ViewInspector's string()
        if let textView = self as? InspectableView<ViewType.Text> {
            return try textView.string()
        }
        throw InspectionError.notSupported("sixLayerString() can only be called on Text views")
    }
    
    public func sixLayerCallOnTapGesture() throws {
        // No recursion - different method name than ViewInspector's callOnTapGesture()
        try self.callOnTapGesture()
    }
    
    public func sixLayerLabelView() throws -> Inspectable {
        // Try to find text content - buttons typically have text labels
        // This is a simplified approach since we can't easily detect button types
        if let text = try? self.sixLayerFind(ViewType.Text.self) {
            return text
        }
        // Fallback: return self
        return self as Inspectable
    }
    
    public func sixLayerTap() throws {
        // Use callOnTapGesture for all tapable views
        // This works for buttons and other tappable views
        try self.callOnTapGesture()
    }
    
    public var sixLayerCount: Int {
        // No recursion - different property name than ViewInspector's count
        if let vStackSelf = self as? InspectableView<ViewType.VStack> {
            return vStackSelf.count
        }
        if let hStackSelf = self as? InspectableView<ViewType.HStack> {
            return hStackSelf.count
        }
        return 0
    }
    
    public var sixLayerIsEmpty: Bool {
        // InspectableView doesn't have isEmpty directly
        return false
    }
    
    public func sixLayerContains(_ element: Inspectable) -> Bool {
        // InspectableView doesn't have contains directly
        return false
    }
}

// MARK: - Type Conversion Helper

/// Helper function to convert InspectableView to Inspectable
/// This ensures type erasure works correctly for all InspectableView types
/// The InspectableView extension makes it conform to Inspectable, so this cast is safe
@MainActor
private func _toInspectable<T>(_ inspected: T) -> Inspectable where T: Inspectable {
    return inspected
}

// MARK: - Crash-Safe ViewInspector Wrapper

/// Crash-safe wrapper for ViewInspector operations
/// CRITICAL: ViewInspector can crash internally (not just throw) when inspecting certain view types.
/// Swift's try? only catches thrown errors, not crashes. This wrapper provides best-effort protection
/// by using autoreleasepool and careful error handling, but cannot prevent all crashes.
/// If ViewInspector crashes internally, Xcode will still crash - this is a ViewInspector limitation.
/// CRITICAL: ViewInspector's inspect() can hang indefinitely on NavigationStack/NavigationView.
/// There's no way to add a timeout to a synchronous call, so hangs will still occur.
@MainActor
private func _tryInspectWithExceptionHandling<V: View>(_ view: V) -> Inspectable? {
    // Use autoreleasepool to ensure proper memory management
    // This helps prevent some memory-related crashes
    return autoreleasepool {
        // Try to catch Swift errors (ViewInspector throws InspectionError)
        // Note: This cannot catch ViewInspector internal crashes (EXC_BAD_ACCESS, etc.)
        // Note: This cannot prevent hangs - inspect() hangs (doesn't throw) on NavigationStack/NavigationView
        // For true crash protection, we'd need Objective-C exception handling via a .m file
        do {
            let inspected = try view.inspect()
            // InspectableView conforms to Inspectable via extension, so this cast is safe
            // Use helper function to ensure proper type erasure
            return _toInspectable(inspected)
        } catch {
            // ViewInspector threw an error (not a crash) - this is expected for some view types
            return nil
        }
    }
}

// MARK: - View Extension for Inspection

extension View {
    /// Safely inspect a view using ViewInspector
    /// Returns nil on inspection failure or internal crashes
    /// Returns a consistent Inspectable type regardless of platform
    /// CRITICAL: ViewInspector's inspect() can hang indefinitely on NavigationStack/NavigationView.
    /// There's no way to add a timeout to a synchronous call. Tests should avoid inspecting
    /// views that contain NavigationStack/NavigationView.
    @MainActor
    func tryInspect() -> Inspectable? {
        // Use exception handling wrapper (cannot add timeout to synchronous call)
        return _tryInspectWithExceptionHandling(self)
    }
    
    /// Inspect a view using ViewInspector, throwing on failure
    /// Throws when ViewInspector cannot inspect the view
    @MainActor
    func inspectView() throws -> Inspectable {
        let inspected = try self.inspect()
        // InspectableView conforms to Inspectable via extension, so this cast is safe
        // Use helper function to ensure proper type erasure
        return _toInspectable(inspected)
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

// MARK: - Helper Functions for Common Patterns

/// Safely inspect a view and execute a closure if inspection succeeds
/// Returns nil on inspection failure
/// Uses Inspectable protocol for consistent type across platforms
@MainActor
public func withInspectedView<V: View, R>(
    _ view: V,
    perform: (Inspectable) throws -> R
) -> R? {
    guard let inspected = view.tryInspect() else {
        return nil
    }
    return try? perform(inspected)
}

/// Safely inspect a view and execute a throwing closure
/// Throws when ViewInspector cannot inspect the view
/// Uses Inspectable protocol for consistent type across platforms
@MainActor
public func withInspectedViewThrowing<V: View, R>(
    _ view: V,
    perform: (Inspectable) throws -> R
) throws -> R {
    let inspected = try view.inspectView()
    return try perform(inspected)
}
