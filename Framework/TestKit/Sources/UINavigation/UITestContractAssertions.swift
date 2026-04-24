//
//  UITestContractAssertions.swift
//  SixLayerTestKit
//
//  Optional XCTest helpers for contract-driven UI checks (#230).
//  See also: Framework/docs/UITestContractAssertions.md
//

#if canImport(XCTest)
import XCTest

/// Optional wrappers around XCTest assertions for XCUI contract checks (#230).
///
/// Prefer native ``XCTAssert`` / ``XCTAssertEqual`` when you already have a concrete ``XCUIQuery`` or need
/// custom failure messages. Use these helpers when you want **consistent diagnostics** for common
/// existence / hittable / identifier checks across consumer suites.
public enum UITestContractAssertions {

    // MARK: - Existence

    /// Fails when `element` does not exist within `timeout` (via ``XCUIElement/waitForExistence``).
    public static func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        _ message: @autoclosure () -> String = "Expected element to exist",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message(), file: file, line: line)
    }

    /// Fails when the element is not hittable after it exists (waits up to `timeout` for existence first).
    public static func assertHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        _ message: @autoclosure () -> String = "Expected element to be hittable",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertExists(element, timeout: timeout, message(), file: file, line: line)
        XCTAssertTrue(element.isHittable, "\(message()) (not hittable)", file: file, line: line)
    }

    // MARK: - Accessibility surface

    /// Fails when ``XCUIElement/identifier`` is empty after the element exists.
    public static func assertNonEmptyAccessibilityIdentifier(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        _ message: @autoclosure () -> String = "Expected non-empty accessibility identifier",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertExists(element, timeout: timeout, message(), file: file, line: line)
        let value = element.identifier
        XCTAssertFalse(value.isEmpty, "\(message()); identifier was empty", file: file, line: line)
    }

    /// Fails when ``XCUIElement/label`` is empty after the element exists.
    ///
    /// - Note: Many SwiftUI controls intentionally expose no accessibility label; skip this assertion unless
    ///   your contract requires a visible VoiceOver label.
    public static func assertNonEmptyAccessibilityLabel(
        _ element: XCUIElement,
        timeout: TimeInterval = 2,
        _ message: @autoclosure () -> String = "Expected non-empty accessibility label",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertExists(element, timeout: timeout, message(), file: file, line: line)
        let value = element.label
        XCTAssertFalse(value.isEmpty, "\(message()); label was empty", file: file, line: line)
    }
}
#endif
