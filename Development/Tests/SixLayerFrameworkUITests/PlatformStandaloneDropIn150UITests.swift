//
//  PlatformStandaloneDropIn150UITests.swift
//  SixLayerFrameworkUITests
//
//  GitHub #150: Real-window interaction and binding validation for standalone drop-in
//  `platformTextField` / `platformSecureField` / `platformToggle` / `platformTextEditor` / `platformForm`.
//  Cross-links: layer semantics / a11y matrices remain #254 / #255 / #256 — not asserted here.
//
//  #316: one section per launch via `-SD150Section=…`; assert by exact accessibilityIdentifier only.
//  Parallel-safe: no shared app, no scroll discovery, no padded waitForExistence timeouts.
//

import XCTest

/// XCUITest for Issue #150 — binding propagation and user interaction on `StandaloneDropIn150HostView`.
@MainActor
final class PlatformStandaloneDropIn150UITests: XCTestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
    }

    nonisolated override func tearDownWithError() throws {
        if let running = app, running.state != .notRunning {
            running.terminate()
        }
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Launch / query (single-path, fail-fast)

    @MainActor
    private func launchSD150Host(section: String) {
        if let running = app, running.state != .notRunning {
            running.terminate()
        }
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.removeAll { $0 == "-SkipAnimations" }
        localApp.launchArguments.append("-OpenStandaloneDropIn150")
        localApp.launchArguments.append("-SD150Section=\(section)")
        localApp.launch()
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "SD150 host should be foreground after launch")

        let sectionId: String
        switch section {
        case "integration": sectionId = "SD150_Section_Integration"
        case "text": sectionId = "SD150_Section_Text"
        case "secure": sectionId = "SD150_Section_Secure"
        case "toggle": sectionId = "SD150_Section_Toggle"
        case "editor": sectionId = "SD150_Section_Editor"
        case "long": sectionId = "SD150_Section_Long"
        default:
            XCTFail("Unknown SD150 section: \(section)")
            return
        }
        XCTAssertTrue(
            element(exactIdentifier: sectionId).exists,
            "SD150 host section '\(sectionId)' should exist at launch (-SD150Section=\(section))"
        )
    }

    /// Single-path query: exact accessibilityIdentifier on any element type.
    @MainActor
    private func element(exactIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", id))
            .firstMatch
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

    @MainActor
    private func focusAndType(_ field: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(field.exists, "Field should exist before typing", file: file, line: line)
        field.xcuiTapToBecomeFirstResponder()
        #if os(iOS)
        XCTAssertTrue(app.keyboards.firstMatch.exists, "Software keyboard should be visible before typeText", file: file, line: line)
        #endif
        field.typeText(text)
    }

    // MARK: - Tests

    func test150_platformTextField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        let field = element(exactIdentifier: "SD150_TextField")
        XCTAssertTrue(field.exists, "SD150_TextField should exist")
        focusAndType(field, "Hello150")
        assertBindingMirrorContains("SD150_Mirror_T", "Hello150")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextField_verticalAxis_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        let field = element(exactIdentifier: "SD150_AxisField")
        XCTAssertTrue(field.exists, "SD150_AxisField should exist")
        focusAndType(field, "AxisX")
        assertBindingMirrorContains("SD150_Mirror_A", "AxisX")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformSecureField_typingUpdatesBinding() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "secure")
        let field = element(exactIdentifier: "SD150_SecureField")
        XCTAssertTrue(field.exists, "SD150_SecureField should exist")
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
        let toggle = element(exactIdentifier: "SD150_Toggle")
        XCTAssertTrue(toggle.exists, "SD150_Toggle should exist")
        toggle.xcuiTapToBecomeFirstResponder()
        assertBindingMirrorContains("SD150_Mirror_G", "1")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformTextEditor_prefillAndAdditionalTyping() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "editor")
        let editor = element(exactIdentifier: "SD150_EditorPrompt")
        XCTAssertTrue(editor.exists, "SD150_EditorPrompt should exist")
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
        let long = String(repeating: "Z", count: 220)
        let field = element(exactIdentifier: "SD150_LongField")
        XCTAssertTrue(field.exists, "SD150_LongField should exist")
        focusAndType(field, long)
        assertBindingMirrorContains("SD150_Mirror_L", String(repeating: "Z", count: 32))
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_rapidSequentialTyping_appends() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "text")
        let field = element(exactIdentifier: "SD150_TextField")
        XCTAssertTrue(field.exists, "SD150_TextField should exist")
        focusAndType(field, "a")
        field.typeText("b")
        assertBindingMirrorContains("SD150_Mirror_T", "ab")
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }

    func test150_platformForm_integrationMultipleControls() throws {
        #if os(iOS) || os(macOS)
        launchSD150Host(section: "integration")
        let name = element(exactIdentifier: "SD150_Integration_Name")
        let pass = element(exactIdentifier: "SD150_Integration_Password")
        let toggle = element(exactIdentifier: "SD150_Integration_Toggle")
        XCTAssertTrue(name.exists, "SD150_Integration_Name should exist")
        XCTAssertTrue(pass.exists, "SD150_Integration_Password should exist")
        // `exactNamed` exposes a host-sentinel `.other` (#364); long-press Paste menus do not
        // appear on that node (iOS 26). Use the same typeText path as other SD150 tests (#368).
        focusAndType(name, "Pat")
        focusAndType(pass, "secret")
        #if os(iOS)
        app.xcuiDismissSoftwareKeyboardIfPresent()
        #endif
        assertBindingMirrorContains("SD150_Mirror_IN", "Pat")
        assertBindingMirrorContains("SD150_Mirror_IN", "secret")
        XCTAssertTrue(toggle.exists, "SD150_Integration_Toggle should exist")
        toggle.xcuiTapToBecomeFirstResponder()
        #else
        throw XCTSkip("Issue #150 host UI tests require iOS or macOS TestApp")
        #endif
    }
}
