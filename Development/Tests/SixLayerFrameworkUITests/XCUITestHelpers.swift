//
//  XCUITestHelpers.swift
//  SixLayerFrameworkUITests
//
//  Performance optimization helpers for XCUITest
//  These utilities help reduce test execution time by optimizing app launch,
//  element queries, and accessibility hierarchy snapshots.
//
//  #348/#351: Prefer launch-arg deep links + exact accessibility identifiers.
//  No scroll-as-discovery / scroll-host query ladders — mount the section via launch args.
//  Type-slot query ladders belong in TestKit's UITestContractElementResolver — not here.
//

import XCTest


// MARK: - XCUIApplication Extensions

extension XCUIApplication {
    /// Configure app for fast UI testing
    /// Sets launch arguments and environment variables to skip slow initialization
    func configureForFastTesting() {
        // Skip animations to speed up UI interactions
        launchArguments = ["-UITesting", "-SkipAnimations"]
        
        // Set environment variable to indicate we're in UI testing mode
        // This allows the app to skip slow initialization paths
        launchEnvironment = ["XCUI_TESTING": "1"]
    }

    /// Swipe down on the software keyboard when present so the next `Form` row can scroll above the
    /// keyboard and accept first responder (Issue #150 / iOS 26 UITest flakes; Refs #261).
    func xcuiDismissSoftwareKeyboardIfPresent() {
        #if os(iOS)
        let board = keyboards.firstMatch
        guard board.exists else { return }
        board.swipeDown()
        let deadline = Date().addingTimeInterval(2.5)
        while keyboards.firstMatch.exists, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        #endif
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {

    /// Best-effort visible/accessible string for XCUI assertions (#316).
    /// macOS SwiftUI often leaves `label` empty for `Text` that also has an accessibilityIdentifier;
    /// content may still appear in `value` or `title`.
    var xcuiAccessibleText: String {
        if !label.isEmpty { return label }
        if let valueString = value as? String, !valueString.isEmpty { return valueString }
        if !title.isEmpty { return title }
        return ""
    }


    /// Tap to become first responder; uses a coordinate tap when `Form` chrome clips hittability.
    /// On iOS, secure fields often need a second tap before `typeText` receives keyboard focus (#150 / iOS 26).
    /// For switches, prefer the trailing thumb region when the control is not hittable.
    func xcuiTapToBecomeFirstResponder() {
        let center = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        #if os(iOS)
        if elementType == .secureTextField {
            center.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            center.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            return
        }
        if elementType == .switch {
            if isHittable {
                tap()
            } else {
                coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            return
        }
        #endif
        if isHittable {
            tap()
        } else {
            center.tap()
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
}

// MARK: - Accessibility Identifier Helpers

extension XCUIElement {
    /// Exact accessibility-identifier query under this element (single `.any` slot — no type ladder).
    /// Prefer host contracts that expose a stable id (#348 / #316).
    func elementMatchingExactIdentifier(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier].firstMatch
    }

    /// Wait for an exact accessibility identifier under this element.
    /// - Returns: the element if it appeared within `timeout`, else `nil`
    func waitForExactIdentifier(_ identifier: String, timeout: TimeInterval = 2.0) -> XCUIElement? {
        let element = elementMatchingExactIdentifier(identifier)
        return element.waitForExistence(timeout: timeout) ? element : nil
    }
}

// MARK: - Accessibility contract verification (DRY)

/// When automaticCompliance is in the chain (e.g. called by a layer or platformButton),
/// we must ensure the correct a11y is present. Requirements differ by element type
/// (e.g. image vs text field): interactive controls need a label; meaningful images
/// need a label; decorative images may not.
///
/// **Pickers:** Per Apple requirements, the picker control must have an identifier and label; options alone do not suffice.
/// When testing a picker, always use verifyPickerAccessibilityContract so the picker itself is asserted first, then option identifiers if provided.
extension XCUIElement {

    /// Whether this element type normally requires an accessibility label when automaticCompliance is applied.
    /// - Parameter type: The expected element type.
    /// - Returns: true for interactive controls (button, textField, switch, slider, link); false for image/other by default.
    private static func labelRequiredForType(_ type: XCUIElement.ElementType) -> Bool {
        switch type {
        case .button, .textField, .switch, .slider, .link:
            return true
        default:
            return false
        }
    }

    /// Verify picker a11y contract per Apple requirements: the picker control MUST have an identifier and label;
    /// having only option elements with IDs does not meet requirements. Option elements must also have identifiers.
    /// Call on the picker element (e.g. the menu button). Option identifiers are often only in the hierarchy when the picker is open.
    /// - Parameters:
    ///   - pickerElementName: Name for failure messages.
    ///   - expectedOptionIdentifiers: Optional list of accessibility identifiers for the picker's options. When provided, asserts each exists. Open the picker first if options are only visible when expanded.
    func verifyPickerAccessibilityContract(
        pickerElementName: String,
        expectedOptionIdentifiers: [String]? = nil
    ) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(pickerElementName): Picker must have accessibility identifier (Apple requirement). Options alone are not sufficient. Found: '\(identifier)'")
        XCTAssertFalse(label.isEmpty,
                       "\(pickerElementName): Picker must have accessibility label (Apple requirement). Found: '\(label)'")
        guard let optionIds = expectedOptionIdentifiers else { return }
        for optionId in optionIds {
            let el = descendants(matching: .any)[optionId].firstMatch
            if !el.waitForExistence(timeout: 1.0) {
                let app = XCUIApplication()
                let anywhere = app.descendants(matching: .any)[optionId].firstMatch
                XCTAssertTrue(anywhere.waitForExistence(timeout: 1.0),
                              "\(pickerElementName) picker option '\(optionId)' should have accessibility identifier (open picker if options are in a menu)")
            }
        }
    }

    /// Verify the full a11y contract for this element type. Use this when automaticCompliance is in the chain.
    /// - Parameters:
    ///   - elementName: Name for failure messages.
    ///   - expectedType: The expected element type (traits).
    ///   - requireLabel: Override label requirement. When nil, uses type default: required for button, textField, switch, slider, link; not for image/staticText (pass true for meaningful images).
    func verifyAccessibilityContract(
        elementName: String,
        expectedType: XCUIElement.ElementType,
        requireLabel: Bool? = nil
    ) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(elementName) should have accessibility identifier. Found: '\(identifier)'")
        XCTAssertEqual(elementType, expectedType,
                       "\(elementName) should have correct accessibility trait. Expected: \(expectedType), Found: \(elementType)")
        let needsLabel = requireLabel ?? Self.labelRequiredForType(expectedType)
        if needsLabel {
            XCTAssertFalse(label.isEmpty,
                           "\(elementName) should have accessibility label for type \(expectedType). Found: '\(label)'")
        }
    }

    /// Verify the element has a non-empty accessibility identifier.
    func verifyAccessibilityIdentifier(elementName: String) {
        XCTAssertFalse(identifier.isEmpty,
                       "\(elementName) should have accessibility identifier. Found: '\(identifier)'")
    }

    /// Verify the element has a non-empty accessibility label. Use for interactive elements (button, textField, switch, slider) or meaningful images.
    /// For type-specific contracts, use verifyAccessibilityContract(elementName:expectedType:requireLabel:) instead.
    func verifyAccessibilityLabel(elementName: String) {
        let needsLabel = elementType == .button || elementType == .textField
            || elementType == .switch || elementType == .slider
        if needsLabel {
            XCTAssertFalse(label.isEmpty,
                           "\(elementName) interactive element should have accessibility label. Found: '\(label)'")
        }
    }

    /// Verify the element has the expected accessibility trait (element type).
    func verifyAccessibilityTraits(elementName: String, expectedType: XCUIElement.ElementType) {
        XCTAssertEqual(elementType, expectedType,
                       "\(elementName) should have correct accessibility trait. Expected: \(expectedType), Found: \(elementType)")
    }
}

extension XCUIApplication {
    /// Wait for a deep-linked host's stable root accessibility identifier (#348 / #316).
    /// Prefer this over navigationBar / staticText OR ladders — hosts must expose the marker.
    /// Uses ``XCUIElement/elementMatchingExactIdentifier(_:)`` (inherited; do not redeclare it here —
    /// XCUIApplication subclasses XCUIElement and cannot override non-@objc extension methods).
    @discardableResult
    func waitForHostRootIdentifier(_ identifier: String, timeout: TimeInterval = 2.5) -> Bool {
        elementMatchingExactIdentifier(identifier).waitForExistence(timeout: timeout)
    }

    /// Runs compatibility-oriented checks on the **current** screen only (Issue #180).
    ///
    /// Call after deep-linking to a host; do **not** use on the bare launch list. Waits are implicit via
    /// `exists` / `waitForExistence` at call sites before sweeping.
    ///
    /// One pass per query axis (`buttons`, `textFields`, `switches`, `sliders`, `staticTexts`). For each element,
    /// runs VoiceOver reachability, readable identity (shared proxy for Dynamic Type readiness and semantic / HC-friendly
    /// naming), and Switch Control–relevant type checks on interactive controls.
    func runAccessibilityCompatibilitySweep(screenLabel: String, file: StaticString = #filePath, line: UInt = #line) {
        let maxPerAxis = 80

        func hint(_ element: XCUIElement) -> String {
            if !element.label.isEmpty { return element.label }
            if !element.identifier.isEmpty { return element.identifier }
            return String(describing: element.elementType)
        }

        let buttonsAxis = buttons.allElementsBoundByIndex
        for i in 0..<min(buttonsAxis.count, maxPerAxis) {
            let element = buttonsAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): button \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): button \"\(h)\" should expose label or identifier (VoiceOver / Dynamic Type readiness)",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .button,
                "\(screenLabel): button \"\(h)\" should surface as .button for Switch Control routing",
                file: file,
                line: line
            )
        }

        let textFieldsAxis = textFields.allElementsBoundByIndex
        for i in 0..<min(textFieldsAxis.count, maxPerAxis) {
            let element = textFieldsAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): text field \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): text field \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .textField,
                "\(screenLabel): text field \"\(h)\" should surface as .textField for Switch Control routing",
                file: file,
                line: line
            )
        }

        let switchesAxis = switches.allElementsBoundByIndex
        for i in 0..<min(switchesAxis.count, maxPerAxis) {
            let element = switchesAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): switch \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): switch \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .switch,
                "\(screenLabel): switch \"\(h)\" should surface as .switch for Switch Control routing",
                file: file,
                line: line
            )
        }

        let slidersAxis = sliders.allElementsBoundByIndex
        for i in 0..<min(slidersAxis.count, maxPerAxis) {
            let element = slidersAxis[i]
            guard element.exists else { continue }
            let h = hint(element)
            XCTAssertTrue(
                element.isHittable || element.isEnabled,
                "\(screenLabel): slider \"\(h)\" should be reachable for VoiceOver",
                file: file,
                line: line
            )
            XCTAssertTrue(
                !element.label.isEmpty || !element.identifier.isEmpty,
                "\(screenLabel): slider \"\(h)\" should expose label or identifier",
                file: file,
                line: line
            )
            XCTAssertEqual(
                element.elementType,
                .slider,
                "\(screenLabel): slider \"\(h)\" should surface as .slider for Switch Control routing",
                file: file,
                line: line
            )
        }

        let statics = staticTexts.allElementsBoundByIndex
        for i in 0..<min(statics.count, maxPerAxis) {
            let element = statics[i]
            guard element.exists else { continue }
            if element.label.isEmpty && element.identifier.isEmpty { continue }
            let h = hint(element)
            if !element.label.isEmpty {
                XCTAssertFalse(
                    element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(screenLabel): static text \"\(h)\" label should not be whitespace-only (VoiceOver / Dynamic Type)",
                    file: file,
                    line: line
                )
            }
            if !element.identifier.isEmpty {
                XCTAssertFalse(
                    element.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(screenLabel): static text \"\(h)\" identifier should not be whitespace-only",
                    file: file,
                    line: line
                )
            }
        }
    }

}

// MARK: - Performance Logging

/// Performance measurement utilities for XCUITest
enum XCUITestPerformance {
    /// Measure time taken for an operation
    /// - Parameter operation: The operation to measure
    /// - Returns: Time taken in seconds
    static func measure<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Measure time taken for an async operation
    /// - Parameter operation: The async operation to measure
    /// - Returns: Time taken in seconds
    static func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Log performance metric
    /// - Parameters:
    ///   - label: Description of what was measured
    ///   - time: Time taken in seconds
    static func log(_ label: String, time: TimeInterval) {
        let milliseconds = Int(time * 1000)
        print("⏱️  [XCUITest Performance] \(label): \(milliseconds)ms")
    }
}

// MARK: - Shared UI interruption monitor (DRY for test setUp)

extension XCTestCase {
    /// Add the standard UI interruption monitor that dismisses system alerts (Bluetooth, CPU, Activity Monitor, etc.).
    /// Call once from setUp in UI test classes. Single implementation so behavior is consistent and changes are in one place.
    func addDefaultUIInterruptionMonitor() {
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { (alert) -> Bool in
            return MainActor.assumeIsolated {
                // Avoid querying alert descendants here; on newer runtimes this can throw
                // snapshot type-mismatch errors for SwiftUI accessibility nodes.
                let alertText = alert.label
                guard alertText.contains("Bluetooth") || alertText.contains("CPU") || alertText.contains("Activity Monitor") else {
                    return false
                }
                if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
                if alert.buttons["Cancel"].exists { alert.buttons["Cancel"].tap(); return true }
                if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
                return false
            }
        }
    }
}
