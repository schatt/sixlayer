//
//  AccessibilityHostIdentifierXCUI.swift
//  SixLayerTestKit
//
//  Type-agnostic XCUI lookup for `accessibilityHostIdentifier` (#473).
//

#if canImport(XCTest)
import XCTest

public extension XCUIElement {
    /// Element with this accessibility identifier, regardless of XCUI type.
    ///
    /// Use this for `accessibilityHostIdentifier` (and `.named` / `.exactNamed` hosts).
    /// On macOS the stamp is a `StaticText` leaf, not `Other` / `ScrollView` (#370 / #473).
    /// Typed queries (`otherElements`, `scrollViews`, `UITestContractElementResolver.findFirstExisting`)
    /// miss or waste slots.
    ///
    /// The matched node is a **sibling leaf**, not a container. Do not use it as a parent
    /// query root (`host.descendants` / `host.cells`) — search again from `app` or the window.
    func elementMatchingAccessibilityIdentifier(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }

    /// Wait until ``elementMatchingAccessibilityIdentifier(_:)`` exists.
    @discardableResult
    func waitForAccessibilityIdentifier(
        _ identifier: String,
        timeout: TimeInterval = 8.0
    ) -> Bool {
        elementMatchingAccessibilityIdentifier(identifier)
            .waitForExistence(timeout: timeout)
    }
}
#endif
