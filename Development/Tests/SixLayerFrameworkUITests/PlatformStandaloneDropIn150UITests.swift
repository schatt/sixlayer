//
//  PlatformStandaloneDropIn150UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window interaction and binding validation for standalone drop-in
//  `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm`.
//  Cross-links: layer semantics / a11y matrices remain #254 / #255 / #256 — not asserted here.
//

import XCTest

/// XCUITest for Issue #150 — binding propagation and user interaction on `StandaloneDropIn150HostView` (`-OpenStandaloneDropIn150`).
@MainActor
final class PlatformStandaloneDropIn150UITests: XCTestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    private static let hostReadyTimeout: TimeInterval = 4.0
    private static let maxFormScrolls = 7

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.removeAll { $0 == "-SkipAnimations" }
            localApp.launchArguments.append("-OpenStandaloneDropIn150")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(
                localApp.wait(for: .runningForeground, timeout: Self.hostReadyTimeout),
                "Test app should be foreground (Issue #150 host)"
            )
            let ready = localApp.navigationBars["SD150 Standalone"].waitForExistence(timeout: Self.hostReadyTimeout)
                || localApp.staticTexts["SD150 Text inputs"].waitForExistence(timeout: 2.0)
            XCTAssertTrue(ready, "SD150 host should show navigation title or first section (launch arg -OpenStandaloneDropIn150)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        if let running = app, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    private func mirrorElement(identifier: String) -> XCUIElement {
        if let found = app.findElement(
            byIdentifier: identifier,
            primaryType: .staticText,
            secondaryTypes: [.any, .other],
            timeout: 1.5
        ) {
            return found
        }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }

    private func scrollUntilHittable(_ element: XCUIElement) {
        for _ in 0..<Self.maxFormScrolls {
            if element.waitForExistence(timeout: 0.35), element.isHittable { return }
            app.xcuiSwipeScrollHostsUp()
        }
    }

    /// `XCUIElementTypeQueryProvider` subscript matching uses accessibility identifiers; SixLayer labels end with `.` (Issue #169).
    private func sd150TextField(labelContains: String) -> XCUIElement {
        let byLabel = NSPredicate(format: "label CONTAINS[c] %@", labelContains)
        let slug = labelContains.lowercased().replacingOccurrences(of: "_", with: "-")
        let byId = NSPredicate(format: "identifier CONTAINS[c] %@", slug)
        return app.textFields.matching(NSCompoundPredicate(orPredicateWithSubpredicates: [byLabel, byId])).firstMatch
    }

    private func sd150SecureField(labelContains: String) -> XCUIElement {
        let slugHyphen = labelContains.lowercased().replacingOccurrences(of: "_", with: "-")
        let slugCompact = labelContains.lowercased().replacingOccurrences(of: "_", with: "")
        let byLabel = NSPredicate(format: "label CONTAINS[c] %@", labelContains)
        let byId = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "identifier CONTAINS[c] %@", slugHyphen),
            NSPredicate(format: "identifier CONTAINS[c] %@", slugCompact)
        ])
        var matchParts: [NSPredicate] = [byLabel, byId]
        if labelContains == "SD150_SecureField" {
            matchParts.append(NSPredicate(format: "identifier == %@", "UITest_SD150_SecureField"))
        }
        let matchA11y = NSCompoundPredicate(orPredicateWithSubpredicates: matchParts)

        // `platformForm` sections: resolve inside the section row (typed queries miss nested SwiftUI fields).
        let sectionHeader: String
        if labelContains.contains("Integration") {
            sectionHeader = "SD150 Integration"
        } else {
            sectionHeader = "SD150 Secure"
        }
        let headerPred = NSPredicate(format: "label == %@", sectionHeader)
        if app.staticTexts[sectionHeader].waitForExistence(timeout: 1.2), app.tables.firstMatch.waitForExistence(timeout: 0.5) {
            let cell = app.tables.firstMatch.cells.containing(headerPred).firstMatch
            let scoped = cell.descendants(matching: .secureTextField).matching(matchA11y).firstMatch
            if scoped.waitForExistence(timeout: 0.6) { return scoped }
            let scopedTF = cell.descendants(matching: .textField).matching(matchA11y).firstMatch
            if scopedTF.waitForExistence(timeout: 0.6) { return scopedTF }
            let anySecure = cell.secureTextFields.firstMatch
            if anySecure.waitForExistence(timeout: 0.4) { return anySecure }
        }

        if labelContains == "SD150_SecureField" {
            let anchor = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "UITest_SD150_SecureField")).firstMatch
            if anchor.waitForExistence(timeout: 1.0) {
                let inner = anchor.descendants(matching: .secureTextField).firstMatch
                if inner.waitForExistence(timeout: 0.6) { return inner }
                let plain = anchor.descendants(matching: .textField).firstMatch
                if plain.waitForExistence(timeout: 0.35) { return plain }
                if anchor.elementType == .secureTextField { return anchor }
            }
        }

        let isSecureOrPlainText = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "elementType == %d", XCUIElement.ElementType.secureTextField.rawValue),
            NSPredicate(format: "elementType == %d", XCUIElement.ElementType.textField.rawValue)
        ])
        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [isSecureOrPlainText, matchA11y])
        return app.descendants(matching: .any).matching(combined).firstMatch
    }

    private func sd150Switch(labelContains: String) -> XCUIElement {
        let byLabel = NSPredicate(format: "label CONTAINS[c] %@", labelContains)
        let slug = labelContains.lowercased().replacingOccurrences(of: "_", with: "-")
        let byId = NSPredicate(format: "identifier CONTAINS[c] %@", slug)
        return app.switches.matching(NSCompoundPredicate(orPredicateWithSubpredicates: [byLabel, byId])).firstMatch
    }

    private func sd150TextView(labelContains: String) -> XCUIElement {
        let byLabel = NSPredicate(format: "label CONTAINS[c] %@", labelContains)
        let slug = labelContains.lowercased().replacingOccurrences(of: "_", with: "-")
        let byId = NSPredicate(format: "identifier CONTAINS[c] %@", slug)
        return app.textViews.matching(NSCompoundPredicate(orPredicateWithSubpredicates: [byLabel, byId])).firstMatch
    }

    /// Single `.tap()` often fails to make secure fields / editors first responder under parallel UI runs (#261).
    private func tapToFocusForTyping(_ element: XCUIElement) {
        scrollUntilHittable(element)
        let point = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        point.tap()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        #if os(iOS)
        let isSecureLike = element.elementType == .secureTextField
            || (element.elementType == .textField && element.identifier.lowercased().contains("securefield"))
        if isSecureLike {
            point.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        #endif
    }

    #if os(iOS)
    private func dismissKeyboardIfPresent() {
        guard app.keyboards.count > 0 else { return }
        let nav = app.navigationBars["SD150 Standalone"].firstMatch
        if nav.waitForExistence(timeout: 0.8) {
            nav.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        let deadline = Date().addingTimeInterval(2.5)
        while Date() < deadline, app.keyboards.count > 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.12))
        }
    }
    #endif

    private func assertBindingMirrorContains(
        _ mirrorId: String,
        _ substring: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let m = mirrorElement(identifier: mirrorId)
        XCTAssertTrue(m.waitForExistence(timeout: 2.5), "Mirror \(mirrorId) should exist", file: file, line: line)
        let text = m.label
        XCTAssertTrue(
            text.contains(substring),
            "Mirror \(mirrorId) should contain '\(substring)'; got label: '\(text)'",
            file: file,
            line: line
        )
    }

    // MARK: - Tests (iOS + macOS TestApp)

    func test150_platformTextField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        let field = sd150TextField(labelContains: "SD150_TextField")
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Text field")
        field.tap()
        field.typeText("Hello150")
        assertBindingMirrorContains("SD150_Mirror_T", "Hello150")
        #if os(iOS)
        XCTAssertEqual((field.value as? String)?.contains("Hello150") ?? false, true, "Text field value should reflect binding")
        #endif
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_verticalAxis_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        let field = sd150TextField(labelContains: "SD150_AxisField")
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Axis text field")
        field.tap()
        field.typeText("AxisX")
        assertBindingMirrorContains("SD150_Mirror_A", "AxisX")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformSecureField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        let field = sd150SecureField(labelContains: "SD150_SecureField")
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Secure field")
        tapToFocusForTyping(field)
        field.typeText("hunter2")
        assertBindingMirrorContains("SD150_Mirror_S", "hunter2")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformToggle_tapUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        let mirrorOff = mirrorElement(identifier: "SD150_Mirror_G")
        scrollUntilHittable(mirrorOff)
        assertBindingMirrorContains("SD150_Mirror_G", "0")
        let toggle = sd150Switch(labelContains: "SD150_Toggle")
        scrollUntilHittable(toggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 2.0), "Toggle")
        #if os(iOS)
        dismissKeyboardIfPresent()
        #endif
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        assertBindingMirrorContains("SD150_Mirror_G", "1")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextEditor_prefillAndAdditionalTyping() throws {
        #if os(iOS) || os(macOS)
        let editor = sd150TextView(labelContains: "SD150_EditorPrompt")
        scrollUntilHittable(editor)
        XCTAssertTrue(editor.waitForExistence(timeout: 2.5), "Text editor")
        assertBindingMirrorContains("SD150_Mirror_E", "PrefillSeed")
        tapToFocusForTyping(editor)
        editor.typeText("More")
        assertBindingMirrorContains("SD150_Mirror_E", "PrefillSeedMore")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_longInputMirror() throws {
        #if os(iOS) || os(macOS)
        let long = String(repeating: "Z", count: 220)
        let field = sd150TextField(labelContains: "SD150_LongField")
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Long field")
        field.tap()
        field.typeText(long)
        assertBindingMirrorContains("SD150_Mirror_L", String(repeating: "Z", count: 32))
        assertBindingMirrorContains("SD150_Mirror_L", "ZZZZ")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_rapidSequentialTyping_appends() throws {
        #if os(iOS) || os(macOS)
        let field = sd150TextField(labelContains: "SD150_TextField")
        scrollUntilHittable(field)
        field.tap()
        field.typeText("a")
        field.typeText("b")
        assertBindingMirrorContains("SD150_Mirror_T", "ab")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformForm_integrationMultipleControls() throws {
        #if os(iOS) || os(macOS)
        let name = sd150TextField(labelContains: "SD150_Integration_Name")
        let pass = sd150SecureField(labelContains: "SD150_Integration_Password")
        let toggle = sd150Switch(labelContains: "SD150_Integration_Toggle")
        XCTAssertTrue(name.waitForExistence(timeout: 2.0), "Integration name")
        scrollUntilHittable(name)
        tapToFocusForTyping(name)
        name.typeText("Pat")
        #if os(iOS)
        dismissKeyboardIfPresent()
        #endif
        XCTAssertTrue(pass.waitForExistence(timeout: 2.0), "Integration password")
        scrollUntilHittable(pass)
        tapToFocusForTyping(pass)
        pass.typeText("secret")
        #if os(iOS)
        dismissKeyboardIfPresent()
        #endif
        scrollUntilHittable(toggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 2.0), "Integration toggle")
        #if os(iOS)
        dismissKeyboardIfPresent()
        #endif
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        assertBindingMirrorContains("SD150_Mirror_IN", "Pat|secret|1")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }
}
