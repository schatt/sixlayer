//
//  AccessibilityIdentifierCategoryAUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A — accessibility identifier scenarios assertable via XCUITest
//  (unicode, nested named, manual-only, special chars, long names).
//  #316: `-OpenCategoryAAccessibility` + `-CatASection=…`; no sharedApp; no scroll discovery.
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryAUITests: XCTestCase {
    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
        // No launch — each test deep-links its section (#316).
    }

    nonisolated override func tearDownWithError() throws {
        if let running = app, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        app = nil
        try super.tearDownWithError()
    }

    private static func sectionMarkerId(_ section: String) -> String {
        switch section {
        case "title": return "CatA_Section_Title"
        case "label": return "CatA_Section_Label"
        case "wrapper": return "CatA_Section_Wrapper"
        case "unicode": return "CatA_Section_Unicode"
        case "nested": return "CatA_Section_Nested"
        case "manual": return "CatA_Section_Manual"
        case "special": return "CatA_Section_Special"
        case "long": return "CatA_Section_Long"
        case "exact": return "CatA_Section_Exact"
        case "empty": return "CatA_Section_Empty"
        case "mid": return "CatA_Section_Mid"
        case "disable": return "CatA_Section_Disable"
        default:
            preconditionFailure("Unknown CatA section: \(section)")
        }
    }

    @MainActor
    private func launchCatA(section: String) {
        if let running = app, running.state != .notRunning {
            running.terminate()
        }
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenCategoryAAccessibility")
        localApp.launchArguments.append("-CatASection=\(section)")
        localApp.launch()
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "CatA host should be foreground")
        let marker = Self.sectionMarkerId(section)
        XCTAssertTrue(
            element(matchingIdentifier: marker).exists,
            "CatA section '\(marker)' should exist at launch (-CatASection=\(section))"
        )
    }

    @MainActor
    private func element(matchingIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    @MainActor
    private func anyElement(identifierContains substring: String) -> XCUIElement {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        return app.descendants(matching: .any).matching(pred).firstMatch
    }

    @MainActor
    private func assertNoIdentifierContaining(_ substring: String) {
        let matches = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", substring))
        XCTAssertEqual(
            matches.count,
            0,
            "No element should expose identifier containing '\(substring)' under disableAutomaticAccessibilityIdentifiers"
        )
    }

    func testCategoryA_unicodeText_hasAccessibilityIdentifier() throws {
        launchCatA(section: "unicode")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAUnicodeText").exists,
            "Unicode identifier name should appear in runtime accessibility identifier (Category A)"
        )
    }

    func testCategoryA_nestedNamed_outerAndInner_haveIdentifiers() throws {
        launchCatA(section: "nested")
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedOuter").exists,
            "Outer named component should contribute to identifier"
        )
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedInnerButton").exists,
            "Inner named component should contribute to identifier"
        )
    }

    func testCategoryA_manualOnlyStaticText_exactIdentifier() throws {
        launchCatA(section: "manual")
        XCTAssertTrue(
            anyElement(identifierContains: "CatA_ManualOnly_StaticText").exists,
            "Manual-only id (platformButton id:) should appear at section launch"
        )
    }

    func testCategoryA_specialCharsInLabel_hasIdentifier() throws {
        launchCatA(section: "special")
        XCTAssertTrue(
            anyElement(identifierContains: "CatASpecialChars").exists,
            "Special characters in label should still yield a stable identifier substring"
        )
    }

    func testCategoryA_longIdentifierName_hasStablePrefixInIdentifier() throws {
        launchCatA(section: "long")
        XCTAssertTrue(
            anyElement(identifierContains: "CatALong").exists,
            "Long identifier name should be represented in accessibility identifier (sanitized prefix)"
        )
    }

    func testCategoryA_auditTitle_namedComponent() throws {
        launchCatA(section: "title")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAAuditTitle").exists,
            "Headline named title should expose identifier for UITest"
        )
    }

    func testCategoryA_exactNamed_minimalIdentifier() throws {
        launchCatA(section: "exact")
        XCTAssertTrue(
            element(matchingIdentifier: "CatAExactNamed").exists,
            "exactNamed should set identifier to the literal name (no SixLayer prefix)"
        )
    }

    func testCategoryA_accessibilityLabel_parameter_surfacesInLabel() throws {
        launchCatA(section: "label")
        let el = anyElement(identifierContains: "CatALabelAndId")
        XCTAssertTrue(el.exists, "identifier should still include CatALabelAndId when accessibilityLabel is set")
        let text = el.xcuiAccessibleText
        XCTAssertTrue(
            text.contains("VoiceOver Cat A Label"),
            "basicAutomaticCompliance accessibilityLabel should appear on XCUIElement; got '\(text)' (label='\(el.label)')"
        )
    }

    func testCategoryA_manualOnOuterGroup_overridesWrapper() throws {
        launchCatA(section: "wrapper")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAManualWinsOnOuter").exists,
            "outer Group accessibilityIdentifier should be findable (manual override on wrapper)"
        )
    }

    func testCategoryA_emptyIdentifierName_sanitizedLabelInIdentifier() throws {
        launchCatA(section: "empty")
        XCTAssertTrue(
            anyElement(identifierContains: "empty-name-row").exists,
            "Empty identifierName should still include sanitized identifierLabel in generated identifier"
        )
    }

    func testCategoryA_midHierarchy_autoSiblingAndOptOut_identifiersPresent() throws {
        launchCatA(section: "mid")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAMidAutoSibling").exists,
            "Named basicAutomaticCompliance row should expose identifier substring"
        )
        XCTAssertTrue(
            anyElement(identifierContains: "CatAMid_LocalOptOut_Static").exists,
            "Explicit platformButton id should match manual-only row pattern"
        )
    }

    func testCategoryA_disableAutomatic_localSubtree_skipsBasicAutomaticIdentifier() throws {
        launchCatA(section: "disable")
        XCTAssertTrue(
            anyElement(identifierContains: "CatADisableMid_AutoPresent").exists,
            "Row outside disable wrapper should still expose basicAutomaticCompliance identifier"
        )
        assertNoIdentifierContaining("CatADisableMid_LocalAutoOff")
    }
}
