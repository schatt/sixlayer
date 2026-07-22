//
//  PlatformStandaloneDropIn150UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window interaction and binding validation for standalone drop-in
//  `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm`.
//  Cross-links: layer semantics / a11y matrices remain #254 / #255 / #256 — not asserted here.
//
//  #316: one section per launch via `-SD150Section=…`; assert by exact accessibilityIdentifier only.
//  #373: reuse app when section launch-arg key matches (text section always fresh — shared fields).
//  No scroll discovery; no padded waitForExistence timeouts.
//

import XCTest

/// XCUITest for Issue #150 — binding propagation and user interaction on `StandaloneDropIn150HostView`.
@MainActor
final class PlatformStandaloneDropIn150UITests: XCTestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    nonisolated(unsafe) private static var sharedApp: XCUIApplication?
    nonisolated(unsafe) private static var sharedLaunchKey: String?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
    }

    nonisolated override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    override class func tearDown() {
        if let running = sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        sharedApp = nil
        sharedLaunchKey = nil
        super.tearDown()
    }

    // MARK: - Launch / query (single-path, fail-fast)

    @MainActor
    private func launchSD150Host(section: String) {
        let key = "OpenStandaloneDropIn150|SD150Section=\(section)|noSkipAnimations"
        // Text section has three mutating tests on shared fields — always fresh launch (#373).
        let canReuse = section != "text"
            && Self.sharedLaunchKey == key
            && Self.sharedApp?.state == .runningForeground
        if canReuse, let existing = Self.sharedApp {
            app = existing
            let sectionId = Self.sectionIdentifier(section)
            XCTAssertTrue(
                element(exactIdentifier: sectionId).waitForExistence(timeout: 8.0),
                "SD150 host section '\(sectionId)' should exist (reused launch, -SD150Section=\(section))"
            )
            return
        }

        if let running = Self.sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        Self.sharedApp = nil
        Self.sharedLaunchKey = nil

        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.removeAll { $0 == "-SkipAnimations" }
        localApp.launchArguments.append("-OpenStandaloneDropIn150")
        localApp.launchArguments.append("-SD150Section=\(section)")
        localApp.launch()
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "SD150 host should be foreground after launch")

        let sectionId = Self.sectionIdentifier(section)
        XCTAssertTrue(
            element(exactIdentifier: sectionId).waitForExistence(timeout: 8.0),
            "SD150 host section '\(sectionId)' should exist at launch (-SD150Section=\(section))"
        )
        Self.sharedApp = localApp
        Self.sharedLaunchKey = key
    }

    private static func sectionIdentifier(_ section: String) -> String {
        switch section {
        case "integration": return "SD150_Section_Integration"
        case "text": return "SD150_Section_Text"
        case "secure": return "SD150_Section_Secure"
        case "toggle": return "SD150_Section_Toggle"
        case "editor": return "SD150_Section_Editor"
        case "long": return "SD150_Section_Long"
        default:
            preconditionFailure("Unknown SD150 section: \(section)")
        }
    }

    /// Single-path query: exact accessibilityIdentifier on any element type.
    @MainActor
    private func element(exactIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
    }

    @MainActor
    private func assertExactIdentifierExists(_ id: String, timeout: TimeInterval = 8.0, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            element(exactIdentifier: id).waitForExistence(timeout: timeout),
            "\(id) should exist",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertBindingMirrorContains(
        _ mirrorId: String,
        _ substring: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let m = element(exactIdentifier: mirrorId)
        XCTAssertTrue(m.exists, "Mirror \(mirrorId) should exist", file: file, line: line)
        // Contract: host sets accessibilityLabel to the mirror text (#316 — no value/title fallback).
        XCTAssertTrue(
            m.label.contains(substring),
            "Mirror \(mirrorId) label should contain '\(substring)'; got label: '\(m.label)'",
            file: file,
            line: line
        )
    }

    /// Resolve the editable leaf when `field` is an `exactNamed` host sentinel (`.other`, #364).
    /// The sentinel is a background sibling, not a parent of the TextField/SecureField/TextEditor.
    @MainActor
    private func editableControl(near hostOrField: XCUIElement) -> XCUIElement {
        switch hostOrField.elementType {
        case .textField, .secureTextField, .textView:
            return hostOrField
        default:
            break
        }
        let token = hostOrField.identifier
        guard !token.isEmpty else { return hostOrField }
        let predicate = NSPredicate(
            format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@ OR placeholderValue CONTAINS[c] %@",
            token, token, token
        )
        let textField = app.descendants(matching: .textField).matching(predicate).firstMatch
        if textField.exists { return textField }
        let secure = app.descendants(matching: .secureTextField).matching(predicate).firstMatch
        if secure.exists { return secure }
        let editor = app.descendants(matching: .textView).matching(predicate).firstMatch
        if editor.exists { return editor }
        return hostOrField
    }

    @MainActor
    private func focusAndType(_ field: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(field.exists, "Field should exist before typing", file: file, line: line)
        let target = editableControl(near: field)
        XCTAssertTrue(target.exists, "Editable control near '\(field.identifier)' should exist", file: file, line: line)
        #if os(iOS)
        // Blur any prior field so SecureField can take first responder in a Form (#368).
        app.xcuiDismissSoftwareKeyboardIfPresent()
        #endif
        target.xcuiTapToBecomeFirstResponder()
        #if os(iOS)
        if target.elementType == .secureTextField {
            typeIntoFocusedSecureField(target, text, file: file, line: line)
            return
        }
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 1.0)
        #endif
        target.typeText(text)
    }

    #if os(iOS)
    /// iOS 26 Form SecureFields often need repeated taps before `typeText` accepts input (#368).
    @MainActor
    private func typeIntoFocusedSecureField(
        _ target: XCUIElement,
        _ text: String,
        file: StaticString,
        line: UInt
    ) {
        let deadline = Date().addingTimeInterval(3.0)
        var focused = false
        while !focused && Date() < deadline {
            target.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            focused = (target.value(forKey: "hasKeyboardFocus") as? Bool) == true
                || app.keyboards.firstMatch.exists
        }
        XCTAssertTrue(
            focused,
            "SecureField '\(target.identifier)' should accept keyboard focus before typeText",
            file: file,
            line: line
        )
        target.typeText(text)
    }
    #endif

    // MARK: - Tests

    func test150_platformTextField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        assertExactIdentifierExists("SD150_TextField")
        let field = element(exactIdentifier: "SD150_TextField")
        focusAndType(field, "Hello150")
        assertBindingMirrorContains("SD150_Mirror_T", "Hello150")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_verticalAxis_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        assertExactIdentifierExists("SD150_AxisField")
        let field = element(exactIdentifier: "SD150_AxisField")
        focusAndType(field, "AxisX")
        assertBindingMirrorContains("SD150_Mirror_A", "AxisX")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformSecureField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "secure")
        assertExactIdentifierExists("SD150_SecureField")
        let field = element(exactIdentifier: "SD150_SecureField")
        focusAndType(field, "hunter2")
        assertBindingMirrorContains("SD150_Mirror_S", "hunter2")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformToggle_tapUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "toggle")
        assertBindingMirrorContains("SD150_Mirror_G", "0")
        assertExactIdentifierExists("SD150_Toggle")
        let toggle = element(exactIdentifier: "SD150_Toggle")
        toggle.xcuiTapToBecomeFirstResponder()
        assertBindingMirrorContains("SD150_Mirror_G", "1")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextEditor_prefillAndAdditionalTyping() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "editor")
        assertExactIdentifierExists("SD150_EditorPrompt")
        let editor = element(exactIdentifier: "SD150_EditorPrompt")
        assertBindingMirrorContains("SD150_Mirror_E", "PrefillSeed")
        focusAndType(editor, "More")
        assertBindingMirrorContains("SD150_Mirror_E", "PrefillSeed")
        assertBindingMirrorContains("SD150_Mirror_E", "More")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_longInputMirror() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "long")
        // Mirror assert only checks the first 32 characters — avoid typing 220 (#373 / #370).
        let long = String(repeating: "Z", count: 40)
        assertExactIdentifierExists("SD150_LongField")
        let field = element(exactIdentifier: "SD150_LongField")
        focusAndType(field, long)
        assertBindingMirrorContains("SD150_Mirror_L", String(repeating: "Z", count: 32))
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_rapidSequentialTyping_appends() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        assertExactIdentifierExists("SD150_TextField")
        let field = element(exactIdentifier: "SD150_TextField")
        focusAndType(field, "a")
        editableControl(near: field).typeText("b")
        assertBindingMirrorContains("SD150_Mirror_T", "ab")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformForm_integrationMultipleControls() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "integration")
        assertExactIdentifierExists("SD150_Integration_Name")
        assertExactIdentifierExists("SD150_Integration_Password")
        let name = element(exactIdentifier: "SD150_Integration_Name")
        let pass = element(exactIdentifier: "SD150_Integration_Password")
        let toggle = element(exactIdentifier: "SD150_Integration_Toggle")
        // `exactNamed` exposes a host-sentinel `.other` (#364); long-press Paste menus do not
        // appear on that node (iOS 26). Use the same typeText path as other SD150 tests (#368).
        focusAndType(name, "Pat")
        focusAndType(pass, "secret")
        #if os(iOS)
        app.xcuiDismissSoftwareKeyboardIfPresent()
        #endif
        assertBindingMirrorContains("SD150_Mirror_IN", "Pat")
        assertBindingMirrorContains("SD150_Mirror_IN", "secret")
        assertExactIdentifierExists("SD150_Integration_Toggle")
        toggle.xcuiTapToBecomeFirstResponder()
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }
}
