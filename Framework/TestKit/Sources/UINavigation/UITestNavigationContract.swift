//
//  UITestNavigationContract.swift
//  SixLayerTestKit
//
//  Public contract identifiers for consumer UI test navigation (#227).
//

import Foundation

// MARK: - Errors

/// Validation failures for UI test navigation contract identifiers.
public enum UITestNavigationContractError: Error, Equatable, Sendable {
    case emptyScreenId
    case emptyRouteId
    case emptyElementId
    case invalidIdentifier(role: String, value: String)
}

extension UITestNavigationContractError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyScreenId:
            return "Screen identifier must not be empty."
        case .emptyRouteId:
            return "Route identifier must not be empty."
        case .emptyElementId:
            return "Element identifier must not be empty."
        case let .invalidIdentifier(role, value):
            return "Invalid \(role) identifier \(value.debugDescription): use only ASCII letters, digits, '.', '-', or '_'."
        }
    }
}

// MARK: - Stable selector types

/// Stable screen-level selector for UI test navigation contracts.
public struct UITestScreenId: Sendable, Hashable, Codable {
    public let rawValue: String

    /// Validates and stores a non-empty screen identifier using ASCII `letters/digits._-` only (after trimming whitespace).
    public init(validating rawValue: String) throws {
        // TDD red stub: accept any string; contract tests require validation before release.
        self.rawValue = rawValue
    }
}

/// Stable route-level selector within a screen.
public struct UITestRouteId: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        self.rawValue = rawValue
    }
}

/// Stable element-level selector (e.g. accessibility identifier contract).
public struct UITestElementId: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        self.rawValue = rawValue
    }
}

// MARK: - Aggregate contract

/// Typed bundle of stable selectors for a single navigation lookup.
public struct UITestNavigationContract: Sendable, Hashable, Codable {
    public let screenId: UITestScreenId
    public let routeId: UITestRouteId?
    public let elementId: UITestElementId?

    public init(screenId: UITestScreenId, routeId: UITestRouteId? = nil, elementId: UITestElementId? = nil) {
        self.screenId = screenId
        self.routeId = routeId
        self.elementId = elementId
    }

    /// Validates string inputs and builds typed identifiers.
    public init(screen: String, route: String? = nil, element: String? = nil) throws {
        self.screenId = try UITestScreenId(validating: screen)
        self.routeId = try route.map { try UITestRouteId(validating: $0) }
        self.elementId = try element.map { try UITestElementId(validating: $0) }
    }
}
