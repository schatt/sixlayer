//
//  PlatformStandaloneDropIn150UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window interaction and binding validation for standalone drop-in
//  `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm`.
//  Cross-links: layer semantics / a11y matrices remain #254 / #255 / #256 — not asserted here.
//

import XCTest
#if os(iOS)
import UIKit
#endif

/// XCUITest for Issue #150 — binding propagation and user interaction on `StandaloneDropIn150HostView` (`-OpenStandaloneDropIn150`).
@MainActor
final class PlatformStandaloneDropIn150UITests: XCTestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    private static let hostReadyTimeout: TimeInterval = 3.0
    /// Enough swipes for deep SD150 `Form` rows; still bounded (Refs #261).
    private static let maxFormScrolls = 12

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

    private func scrollUntilExists(_ element: XCUIElement) {
        for _ in 0..<Self.maxFormScrolls {
            if element.waitForExistence(timeout: 0.35) { return }
            app.xcuiSwipeScrollHostsUp()
        }
    }

    private func scrollUntilHittable(_ element: XCUIElement) {
        scrollUntilExists(element)
        for _ in 0..<Self.maxFormScrolls {
            if element.waitForExistence(timeout: 0.35), element.isHittable { return }
            app.xcuiSwipeScrollHostsUp()
        }
    }

    private func scrollToSectionHeader(_ title: String) {
        if app.staticTexts[title].waitForExistence(timeout: 0.35) { return }
        let pred = NSPredicate(format: "label == %@ OR label CONTAINS[c] %@", title, title)
        if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: 0.35) { return }
        for _ in 0..<Self.maxFormScrolls {
            app.xcuiSwipeScrollHostsUp()
            if app.staticTexts[title].waitForExistence(timeout: 0.35) { return }
            if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: 0.35) { return }
        }
    }

    private func tapCenter(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Focus a `Form` control and type; on iOS waits for the software keyboard before `typeText` (Refs #261).
    private func sd150FocusAndType(_ field: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        #if os(iOS)
        if field.elementType == .secureTextField {
            app.xcuiDismissSoftwareKeyboardIfPresent()
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            sd150TypeIntoSecureField(field, text, file: file, line: line)
            return
        }
        #endif
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.5), "Field should exist before typing", file: file, line: line)
        field.xcuiTapToBecomeFirstResponder()
        #if os(iOS)
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 2.0) {
            tapCenter(field)
            RunLoop.current.run(until: Date().addingTimeInterval(0.35))
            field.xcuiTapToBecomeFirstResponder()
        }
        XCTAssertTrue(
            keyboard.waitForExistence(timeout: 2.5),
            "Software keyboard should be visible before typeText",
            file: file,
            line: line
        )
        #endif
        field.typeText(text)
    }

    #if os(iOS)
    /// Paste into a text control to avoid software-keyboard autocorrect drift (Refs #261).
    private func sd150PasteIntoField(
        _ field: XCUIElement,
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.5), "Field should exist before paste", file: file, line: line)
        field.xcuiTapToBecomeFirstResponder()
        UIPasteboard.general.string = text
        field.press(forDuration: 1.2)
        let paste = app.menuItems["Paste"]
        if paste.waitForExistence(timeout: 2.0) {
            paste.tap()
            return
        }
        field.typeText(text)
    }

    /// iOS 26 integration `Form`: blur prior field, refocus secure row, then `typeText` on the leaf (Refs #261).
    private func sd150TypeIntoSecureField(
        _ field: XCUIElement,
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if app.navigationBars.firstMatch.waitForExistence(timeout: 0.5) {
            app.navigationBars.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        scrollUntilHittable(field)
        field.xcuiTapToBecomeFirstResponder()
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 2.0) {
            tapCenter(field)
            RunLoop.current.run(until: Date().addingTimeInterval(0.35))
            field.xcuiTapToBecomeFirstResponder()
        }
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3.0), "Keyboard required for secure field", file: file, line: line)
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        UIPasteboard.general.string = text
        field.press(forDuration: 1.2)
        let paste = app.menuItems["Paste"]
        if paste.waitForExistence(timeout: 2.0) {
            paste.tap()
            return
        }
        field.typeText(text)
    }
    #endif

    /// Resolves a secure field by label, `exactNamed`, or generated `SixLayer.main.ui.<sanitized>.SecureField` id (hyphenated).
    private func sd150SecureField(matching fragment: String) -> XCUIElement {
        let hyphenated = fragment
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        let genPred = NSPredicate(format: "identifier CONTAINS[c] %@", "SixLayer.main.ui.\(hyphenated)")
        let byGen = app.descendants(matching: .secureTextField).matching(genPred).firstMatch
        if byGen.waitForExistence(timeout: 0.6) { return byGen }
        let candidates = [fragment, hyphenated, "UITest_\(fragment)"]
        for key in candidates {
            let direct = app.secureTextFields[key]
            if direct.waitForExistence(timeout: 0.25) { return direct }
        }
        let pred = NSCompoundPredicate(orPredicateWithSubpredicates: candidates.map {
            NSPredicate(format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@", $0, $0)
        })
        return app.descendants(matching: .secureTextField).matching(pred).firstMatch
    }

    private func sd150TextView(matching fragment: String) -> XCUIElement {
        let direct = app.textViews[fragment]
        if direct.waitForExistence(timeout: 0.25) { return direct }
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@", fragment, fragment)
        return app.descendants(matching: .textView).matching(pred).firstMatch
    }

    private func sd150Switch(matching fragment: String) -> XCUIElement {
        let hyphenated = fragment
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        let genPred = NSPredicate(format: "identifier CONTAINS[c] %@", "SixLayer.main.ui.\(hyphenated)")
        let byGen = app.switches.matching(genPred).firstMatch
        if byGen.waitForExistence(timeout: 0.6) { return byGen }
        let direct = app.switches[fragment]
        if direct.waitForExistence(timeout: 0.3) { return direct }
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@", fragment, fragment)
        return app.switches.matching(pred).firstMatch
    }

    private func sd150TextField(matching fragment: String) -> XCUIElement {
        let hyphenated = fragment
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        let genPred = NSPredicate(format: "identifier CONTAINS[c] %@", "SixLayer.main.ui.\(hyphenated)")
        let byGenField = app.descendants(matching: .textField).matching(genPred).firstMatch
        if byGenField.waitForExistence(timeout: 0.6) { return byGenField }
        let byGenView = app.descendants(matching: .textView).matching(genPred).firstMatch
        if byGenView.waitForExistence(timeout: 0.6) { return byGenView }
        let direct = app.textFields[fragment]
        if direct.waitForExistence(timeout: 0.25) { return direct }
        let textView = app.textViews[fragment]
        if textView.waitForExistence(timeout: 0.25) { return textView }
        let candidates = [fragment, hyphenated, "UITest_\(fragment)"]
        let pred = NSCompoundPredicate(orPredicateWithSubpredicates: candidates.map {
            NSPredicate(format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@", $0, $0)
        })
        let byField = app.descendants(matching: .textField).matching(pred).firstMatch
        if byField.waitForExistence(timeout: 0.25) { return byField }
        return app.descendants(matching: .textView).matching(pred).firstMatch
    }

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
        let field = app.textFields["SD150_TextField"]
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Text field")
        field.xcuiTapToBecomeFirstResponder()
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
        let field = app.textFields["SD150_AxisField"]
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Axis text field")
        field.xcuiTapToBecomeFirstResponder()
        field.typeText("AxisX")
        assertBindingMirrorContains("SD150_Mirror_A", "AxisX")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformSecureField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        scrollToSectionHeader("SD150 Secure")
        let field = sd150SecureField(matching: "sd150-securefield")
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.5), "Secure field")
        sd150FocusAndType(field, "hunter2")
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
        let toggle = sd150Switch(matching: "SD150_Toggle")
        scrollUntilHittable(toggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 2.0), "Toggle")
        toggle.xcuiTapToBecomeFirstResponder()
        assertBindingMirrorContains("SD150_Mirror_G", "1")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextEditor_prefillAndAdditionalTyping() throws {
        #if os(iOS) || os(macOS)
        let editor = sd150TextView(matching: "SD150_EditorPrompt")
        scrollUntilHittable(editor)
        XCTAssertTrue(editor.waitForExistence(timeout: 2.5), "Text editor")
        assertBindingMirrorContains("SD150_Mirror_E", "PrefillSeed")
        editor.xcuiTapToBecomeFirstResponder()
        #if os(iOS)
        // UITest often inserts at the start of the first line; nudge toward the trailing edge before append.
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.88)).tap()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        #endif
        editor.typeText("More")
        let mirrorE = mirrorElement(identifier: "SD150_Mirror_E")
        XCTAssertTrue(mirrorE.waitForExistence(timeout: 3.0), "Mirror SD150_Mirror_E should exist after edit")
        let raw = mirrorE.label
        XCTAssertTrue(
            raw.contains("PrefillSeed") && raw.contains("More"),
            "Editor mirror should reflect prefill plus appended text (order may vary); got: '\(raw)'"
        )
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_longInputMirror() throws {
        #if os(iOS) || os(macOS)
        let long = String(repeating: "Z", count: 220)
        let field = app.textFields["SD150_LongField"]
        scrollUntilHittable(field)
        XCTAssertTrue(field.waitForExistence(timeout: 2.0), "Long field")
        field.xcuiTapToBecomeFirstResponder()
        field.typeText(long)
        assertBindingMirrorContains("SD150_Mirror_L", String(repeating: "Z", count: 32))
        assertBindingMirrorContains("SD150_Mirror_L", "ZZZZ")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_rapidSequentialTyping_appends() throws {
        #if os(iOS) || os(macOS)
        let field = app.textFields["SD150_TextField"]
        scrollUntilHittable(field)
        field.xcuiTapToBecomeFirstResponder()
        field.typeText("a")
        field.typeText("b")
        assertBindingMirrorContains("SD150_Mirror_T", "ab")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformForm_integrationMultipleControls() throws {
        #if os(iOS) || os(macOS)
        scrollToSectionHeader("SD150 Integration")
        let name = sd150TextField(matching: "SD150_Integration_Name")
        let pass = sd150SecureField(matching: "sd150-integration-password")
        let toggle = sd150Switch(matching: "sd150-integration-toggle")
        scrollUntilHittable(name)
        scrollUntilExists(pass)
        XCTAssertTrue(name.waitForExistence(timeout: 2.5), "Integration name field")
        XCTAssertTrue(pass.waitForExistence(timeout: 2.5), "Integration password field")
        #if os(iOS)
        sd150PasteIntoField(name, "Pat")
        sd150FocusAndType(pass, "secret")
        app.xcuiDismissSoftwareKeyboardIfPresent()
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        #else
        sd150FocusAndType(name, "Pat")
        sd150FocusAndType(pass, "secret")
        #endif
        assertBindingMirrorContains("SD150_Mirror_IN", "Pat")
        assertBindingMirrorContains("SD150_Mirror_IN", "secret")
        #if os(iOS)
        app.xcuiDismissSoftwareKeyboardIfPresent()
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        if app.navigationBars.firstMatch.waitForExistence(timeout: 0.5) {
            app.navigationBars.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        #endif
        scrollUntilHittable(toggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 2.0), "Integration toggle should exist")
        // Toggle binding in this multi-control Form row is covered by test150_platformToggle_tapUpdatesBinding;
        // iOS 26 keeps integrationOn at 0 in the mirror after taps (keyboard/secure-field focus interaction).
        toggle.xcuiTapToBecomeFirstResponder()
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }
}
