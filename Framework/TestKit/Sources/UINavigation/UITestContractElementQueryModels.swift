//
//  UITestContractElementQueryModels.swift
//  SixLayerTestKit
//
//  Cross-platform XCUI contract query slot ordering (#228).
//  See also: Framework/docs/UITestContractElementResolver.md
//

import Foundation

// MARK: - Configuration

/// Timeout semantics for ``UITestContractElementResolverCore`` / ``UITestContractElementResolver``.
///
/// Each slot in the fallback sequence is tried in order. For every slot, the implementation waits up to
/// ``timeoutPerSlot`` for a materialized element to exist (e.g. `XCUIElement.waitForExistence`). There is
/// no implicit global deadline beyond the sum of per-slot waits unless you choose a small
/// ``timeoutPerSlot`` and a short slot list.
public struct UITestContractElementResolverConfiguration: Sendable, Hashable {
    /// Maximum time to wait for a candidate element to appear for a single query slot.
    public var timeoutPerSlot: TimeInterval

    public init(timeoutPerSlot: TimeInterval = 0.25) {
        self.timeoutPerSlot = timeoutPerSlot
    }
}

// MARK: - Query slots (ordering is API)

/// Logical XCUI element categories used when resolving a stable accessibility identifier.
///
/// The **numeric raw value is not API**; ordering is defined only by ``contractResolutionOrder``.
public enum UITestContractXCUIQuerySlot: Int, Sendable, Equatable, Hashable, Codable {
    case button
    case cell
    case link
    case staticText
    case image
    case toggle
    case other

    /// Deterministic cross-platform resolution order for contract identifiers.
    ///
    /// Policy: prefer direct controls (`button`, `toggle`), then list/table surfaces (`cell`), tappable text (`link`),
    /// read-only text (`staticText`), decorative or iconic hits (`image`), and finally `other` as a wide net
    /// (maps to ``XCUIElement.ElementType/other``). Adjust only with semver and doc updates.
    public static var contractResolutionOrder: [UITestContractXCUIQuerySlot] {
        [.button, .cell, .link, .staticText, .image, .toggle, .other]
    }
}

// MARK: - Testable resolution core

/// Shared fallback scanning logic for UI test contract resolution (#228).
///
/// Module-internal so `@testable import SixLayerTestKit` can lock ordering without expanding the public surface.
enum UITestContractElementResolverCore {
    /// Returns the first slot whose materialized value exists within the per-slot timeout budget.
    static func firstResolved<Materialized>(
        slots: [UITestContractXCUIQuerySlot],
        elementId: UITestElementId,
        timeoutPerSlot: TimeInterval,
        materialize: (UITestContractXCUIQuerySlot) -> Materialized?,
        exists: (_ value: Materialized, _ timeout: TimeInterval) -> Bool
    ) -> (slot: UITestContractXCUIQuerySlot, match: Materialized)? {
        _ = elementId
        for slot in slots {
            guard let materialized = materialize(slot) else { continue }
            if exists(materialized, timeoutPerSlot) {
                return (slot, materialized)
            }
        }
        return nil
    }
}
