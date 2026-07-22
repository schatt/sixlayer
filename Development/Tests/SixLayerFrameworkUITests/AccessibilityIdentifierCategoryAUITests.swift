//
//  AccessibilityIdentifierCategoryAUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A — accessibility identifier scenarios assertable via XCUITest
//  (unicode, nested named, manual-only, special chars, long names).
//  #316: deep-link via `-OpenCategoryAAccessibility` (no launch-menu navigation).
//  #374: one full-host launch (no per-test `-CatASection=`); assert exact/CONTAINS ids only —
//  no scroll-as-discovery.
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryAUITests: XCTestCase {
    nonisolated(unsafe) private var app: XCUIApplication!
    nonisolated(unsafe) private static var sharedApp: XCUIApplication?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        if let existing = Self.sharedApp, existing.state == .runningForeground {
            app = existing
            return
        }

        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        // Full audit host — all sections mounted (no `-CatASection=`). Refs #374 / #316.
        localApp.launchArguments.append("-OpenCategoryAAccessibility")
        localApp.launch()
        Self.sharedApp = localApp
        app = localApp
        XCTAssertEqual(localApp.state, .runningForeground, "CatA host should be foreground")
        XCTAssertTrue(
            element(matchingIdentifier: "CatA_Section_Title").waitForExistence(timeout: 2.5),
            "CatA full host should expose CatA_Section_Title at launch (-OpenCategoryAAccessibility)"
        )
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
        super.tearDown()
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

    @MainActor
    private func assertSectionPresent(_ sectionMarker: String) {
        XCTAssertTrue(
            element(matchingIdentifier: sectionMarker).exists,
            "CatA full host should expose section marker '\(sectionMarker)'"
        )
    }

    func testCategoryA_unicodeText_hasAccessibilityIdentifier() throws {
        assertSectionPresent("CatA_Section_Unicode")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAUnicodeText").exists,
            "Unicode identifier name should appear in runtime accessibility identifier (Category A)"
        )
    }

    func testCategoryA_nestedNamed_outerAndInner_haveIdentifiers() throws {
        assertSectionPresent("CatA_Section_Nested")
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
        assertSectionPresent("CatA_Section_Manual")
        XCTAssertTrue(
            anyElement(identifierContains: "CatA_ManualOnly_StaticText").exists,
            "Manual-only id (platformButton id:) should appear on full CatA host"
        )
    }

    func testCategoryA_specialCharsInLabel_hasIdentifier() throws {
        assertSectionPresent("CatA_Section_Special")
        XCTAssertTrue(
            anyElement(identifierContains: "CatASpecialChars").exists,
            "Special characters in label should still yield a stable identifier substring"
        )
    }

    func testCategoryA_longIdentifierName_hasStablePrefixInIdentifier() throws {
        assertSectionPresent("CatA_Section_Long")
        XCTAssertTrue(
            anyElement(identifierContains: "CatALong").exists,
            "Long identifier name should be represented in accessibility identifier (sanitized prefix)"
        )
    }

    func testCategoryA_auditTitle_namedComponent() throws {
        assertSectionPresent("CatA_Section_Title")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAAuditTitle").exists,
            "Headline named title should expose identifier for UITest"
        )
    }

    func testCategoryA_exactNamed_minimalIdentifier() throws {
        assertSectionPresent("CatA_Section_Exact")
        XCTAssertTrue(
            element(matchingIdentifier: "CatAExactNamed").exists,
            "exactNamed should set identifier to the literal name (no SixLayer prefix)"
        )
    }

    func testCategoryA_accessibilityLabel_parameter_surfacesInLabel() throws {
        assertSectionPresent("CatA_Section_Label")
        let el = anyElement(identifierContains: "CatALabelAndId")
        XCTAssertTrue(el.exists, "identifier should still include CatALabelAndId when accessibilityLabel is set")
        let text = el.xcuiAccessibleText
        XCTAssertTrue(
            text.contains("VoiceOver Cat A Label"),
            "basicAutomaticCompliance accessibilityLabel should appear on XCUIElement; got '\(text)' (label='\(el.label)')"
        )
    }

    func testCategoryA_manualOnOuterGroup_overridesWrapper() throws {
        assertSectionPresent("CatA_Section_Wrapper")
        XCTAssertTrue(
            anyElement(identifierContains: "CatAManualWinsOnOuter").exists,
            "outer Group accessibilityIdentifier should be findable (manual override on wrapper)"
        )
    }

    func testCategoryA_emptyIdentifierName_sanitizedLabelInIdentifier() throws {
        assertSectionPresent("CatA_Section_Empty")
        XCTAssertTrue(
            anyElement(identifierContains: "empty-name-row").exists,
            "Empty identifierName should still include sanitized identifierLabel in generated identifier"
        )
    }

    func testCategoryA_midHierarchy_autoSiblingAndOptOut_identifiersPresent() throws {
        assertSectionPresent("CatA_Section_Mid")
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
        assertSectionPresent("CatA_Section_Disable")
        XCTAssertTrue(
            anyElement(identifierContains: "CatADisableMid_AutoPresent").exists,
            "Row outside disable wrapper should still expose basicAutomaticCompliance identifier"
        )
        assertNoIdentifierContaining("CatADisableMid_LocalAutoOff")
    }
}
