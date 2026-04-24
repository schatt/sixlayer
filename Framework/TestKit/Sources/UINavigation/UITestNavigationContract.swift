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

// MARK: - Identifier validation

private enum UITestIdentifierValidation {
    static func normalizedRawValue(
        _ raw: String,
        emptyError: UITestNavigationContractError,
        role: String
    ) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw emptyError }
        guard trimmed.unicodeScalars.allSatisfy(isAllowedASCII) else {
            throw UITestNavigationContractError.invalidIdentifier(role: role, value: trimmed)
        }
        return trimmed
    }

    private static func isAllowedASCII(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A: true // 0-9 A-Z a-z
        case 0x2E, 0x2D, 0x5F: true // . - _
        default: false
        }
    }
}

// MARK: - Stable selector types

/// Stable screen-level selector for UI test navigation contracts.
public struct UITestScreenId: Sendable, Hashable, Codable {
    public let rawValue: String

    /// Validates and stores a non-empty screen identifier using ASCII `letters/digits._-` only (after trimming whitespace).
    public init(validating rawValue: String) throws {
        self.rawValue = try UITestIdentifierValidation.normalizedRawValue(
            rawValue,
            emptyError: .emptyScreenId,
            role: "screen"
        )
    }
}

/// Stable route-level selector within a screen.
public struct UITestRouteId: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        self.rawValue = try UITestIdentifierValidation.normalizedRawValue(
            rawValue,
            emptyError: .emptyRouteId,
            role: "route"
        )
    }
}

/// Stable element-level selector (e.g. accessibility identifier contract).
public struct UITestElementId: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        self.rawValue = try UITestIdentifierValidation.normalizedRawValue(
            rawValue,
            emptyError: .emptyElementId,
            role: "element"
        )
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
