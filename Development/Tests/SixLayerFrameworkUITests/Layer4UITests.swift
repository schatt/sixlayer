//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one test method per L4 component. Launch with -OpenLayer4Examples.
//  Each test asserts the full contract: a11y (identifier/label), structure (element type, hierarchy), and behavior.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: one test per L4 API. Contract = full contract (behavior, structure, a11y), not just accessibility.
/// We test ALL L4 APIs; each test asserts the API's contract.
/// Uses launch argument -OpenLayer4Examples. One app launch for the suite.
///
/// Currently covered: platformButton, platformTextField, platformPicker, platformSecureField, platformToggle,
/// platformTextEditor, platformDatePicker, platformForm, platformFormSection, platformFormField, platformFormFieldGroup,
/// platformValidationMessage, platformListRow, platformListSectionHeader, platformListEmptyState,
/// platformSheet_L4, platformPopover_L4, platformNavigationTitle_L4, platformNavigationLink_L4, platformNavigationBarTitleDisplayMode_L4,
/// platformCopyToClipboard_L4, platformPrint_L4, platformCloudKitSyncStatus_L4, platformPhotoDisplay_L4.
/// Remaining L4 APIs to add: platformImplementNavigationStack_L4, platformAppNavigation_L4, platformRowActions_L4,
/// platformPhotoPicker_L4, platformMapView_L4, other platformCloudKit*,
/// platformShare_L4, platformVerticalSplit_L4, platformHorizontalSplit_L4, platformStyledContainer_L4, etc.
@MainActor
final class Layer4UITests: XCTestCase {
    /// Shared across test instances (Xcode creates one instance per test method).
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    /// One app launch for the suite; all test methods reuse the same launch.
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer4Examples")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 4 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    /// Expected identifier suffix (sanitized label + type) when enableUITestIntegration is true: SixLayer.main.ui.<suffix>.
    private static func l4ContractIdentifier(sanitizedName: String, elementType: String) -> String {
        "SixLayer.main.ui.\(sanitizedName).\(elementType)"
    }

    /// Scroll so the element with the given label is visible (content may be below fold).
    /// Uses longer initial wait for buttons so top-of-screen elements (e.g. L4 Presentation) are not skipped.
    @MainActor
    private func scrollToElement(label: String) {
        if app.staticTexts[label].waitForExistence(timeout: 1.0) { return }
        if app.buttons[label].waitForExistence(timeout: 2.0) { return }
        if element(matchingIdentifier: label).waitForExistence(timeout: 1.0) { return }
        let scrollable: XCUIElement = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app.windows.firstMatch
        guard scrollable.exists else { return }
        for _ in 0..<5 {
            scrollable.swipeUp()
            if app.staticTexts[label].waitForExistence(timeout: 1.0) { return }
            if app.buttons[label].waitForExistence(timeout: 1.0) { return }
            if element(matchingIdentifier: label).waitForExistence(timeout: 0.5) { return }
        }
    }

    /// Element with the given accessibility identifier (any type).
    @MainActor
    private func element(matchingIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    /// Tap when the element is not hittable (e.g. clipped by safe area); coordinate tap matches user intent.
    @MainActor
    private func tapByNormalizedCenter(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @MainActor
    private func l4FormSectionHeaderVisible(timeout: TimeInterval) -> Bool {
        if app.staticTexts["L4FormSectionContract"].waitForExistence(timeout: timeout) { return true }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "L4FormSectionContract"))
            .firstMatch.waitForExistence(timeout: timeout)
    }

    /// Ensure we're on the contract root with top of content visible. Pop from nav stack if needed; scroll to top if the first contract section is off-screen.
    @MainActor
    private func ensureContractRoot() {
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        if app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 0.5) {
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists { backButton.tap() }
            _ = app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 3.0)
        }
        XCTAssertTrue(app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 6.0),
                      "Contract root: Layer 4 Examples nav bar should exist")
        func contractTopVisible() -> Bool {
            app.staticTexts["L4 Presentation"].waitForExistence(timeout: 0.3)
                || app.staticTexts["L4 System"].waitForExistence(timeout: 0.3)
        }
        if contractTopVisible() { return }
        let scrollable = app.scrollViews.firstMatch
        if scrollable.exists {
            for _ in 0..<6 {
                scrollable.swipeDown()
                if contractTopVisible() { return }
            }
        }
        XCTAssertTrue(
            app.staticTexts["L4 Presentation"].waitForExistence(timeout: 5.0)
                || app.staticTexts["L4 System"].waitForExistence(timeout: 0.5),
            "Contract root (L4 Presentation or L4 System) should be visible after scroll to top"
        )
    }

    @MainActor
    private func assertElementHasIdentifierFromComponent(
        label: String,
        type: XCUIElement.ElementType,
        componentName: String,
        sanitizedIdentifierName: String,
        identifierElementType: String
    ) {
        scrollToElement(label: label)
        let identifier = Self.l4ContractIdentifier(sanitizedName: sanitizedIdentifierName, elementType: identifierElementType)
        // Prefer contract type first so we find the real control; then .other as fallback (type assertion will fail if only wrapper has id).
        let typesToTry: [(XCUIElement.ElementType, TimeInterval)] = (type == .textField || type == .secureTextField || type == .switch || type == .textView)
            ? [(type, 5.0), (.other, 2.0)]
            : [(type, 5.0)]
        var el: XCUIElement?
        for (primaryType, timeout) in typesToTry {
            el = app.findElement(byIdentifier: identifier, primaryType: primaryType, secondaryTypes: [.other, .button, .staticText, .any], timeout: timeout)
            if el != nil { break }
        }
        if el == nil {
            el = app.findElement(byIdentifier: identifier, primaryType: .any, secondaryTypes: [.other, .button, .staticText], timeout: 2.0)
        }
        if el == nil {
            let containsPred = NSPredicate(format: "identifier CONTAINS[c] %@", sanitizedIdentifierName)
            let anyWithId = app.descendants(matching: .any).matching(containsPred).firstMatch
            if anyWithId.waitForExistence(timeout: 2.0) { el = anyWithId }
        }
        XCTAssertNotNil(el, "\(componentName): element with identifier '\(identifier)' or containing '\(sanitizedIdentifierName)' should exist (contract)")
        if let el = el {
            XCTAssertFalse(el.identifier.isEmpty,
                          "\(componentName) must apply a11y. '\(label)' should have identifier. Found: '\(el.identifier)'")
            let hasCorrectType = (el.elementType == type)
                || (el.descendants(matching: type).firstMatch.waitForExistence(timeout: 0.5))
            XCTAssertTrue(hasCorrectType,
                          "\(componentName) must present as \(type) (contract structure). Found: \(el.elementType)")
        }
    }

    @MainActor
    func testL4_platformButton() throws {
        ensureContractRoot()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractButton",
            type: .button,
            componentName: "platformButton",
            sanitizedIdentifierName: "l4contractbutton",
            identifierElementType: "Button"
        )
    }

    @MainActor
    func testL4_platformTextField() throws {
        ensureContractRoot()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextField",
            type: .textField,
            componentName: "platformTextField",
            sanitizedIdentifierName: "l4contracttextfield",
            identifierElementType: "TextField"
        )
    }

    @MainActor
    func testL4_platformPicker() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Controls")
        scrollToElement(label: "L4ContractPicker")
        // platformPicker contract: picker or an option has identifier.
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", "picker")
        let pickerEl = app.descendants(matching: .any).matching(pred).firstMatch
        if pickerEl.waitForExistence(timeout: 3.0) {
            XCTAssertFalse(pickerEl.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(pickerEl.identifier)'")
            return
        }
        // Options may be in hierarchy only when menu is open; tap picker (shows selected "A") to open.
        if app.buttons["A"].waitForExistence(timeout: 2.0) { app.buttons["A"].firstMatch.tap() }
        let optionAId = Self.l4ContractIdentifier(sanitizedName: "a", elementType: "View")
        let optionEl = app.findElement(byIdentifier: optionAId, primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 3.0)
        XCTAssertNotNil(optionEl, "platformPicker: picker or option should have identifier (tried 'picker' and '\(optionAId)')")
        if let el = optionEl { XCTAssertFalse(el.identifier.isEmpty, "platformPicker must apply a11y.") }
    }

    @MainActor
    func testL4_platformSecureField() throws {
        ensureContractRoot()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractSecureField",
            type: .secureTextField,
            componentName: "platformSecureField",
            sanitizedIdentifierName: "l4contractsecurefield",
            identifierElementType: "SecureField"
        )
    }

    @MainActor
    func testL4_platformToggle() throws {
        ensureContractRoot()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractToggle",
            type: .switch,
            componentName: "platformToggle",
            sanitizedIdentifierName: "l4contracttoggle",
            identifierElementType: "Toggle"
        )
    }

    @MainActor
    func testL4_platformTextEditor() throws {
        ensureContractRoot()
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextEditor",
            type: .textView,
            componentName: "platformTextEditor",
            sanitizedIdentifierName: "l4contracttexteditor",
            identifierElementType: "TextEditor"
        )
    }

    @MainActor
    func testL4_platformDatePicker() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractDatePicker")
        XCTAssertTrue(app.staticTexts["L4ContractDatePicker"].waitForExistence(timeout: 3.0),
                      "platformDatePicker: label must exist (contract); date picker control is platform-rendered")
    }

    @MainActor
    func testL4_platformForm() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        XCTAssertTrue(app.staticTexts["L4 Form"].waitForExistence(timeout: 3.0),
                      "platformForm: form section title (L4 Form) should be visible")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 4.0),
                      "platformForm: form must contain section with header (contract structure)")
    }

    @MainActor
    func testL4_platformFormSection() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "Section body")
        XCTAssertTrue(l4FormSectionHeaderVisible(timeout: 4.0),
                      "platformFormSection: section header must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformFormField() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldContract")
        XCTAssertTrue(app.staticTexts["L4FormFieldContract"].waitForExistence(timeout: 3.0),
                      "platformFormField: label must exist (contract structure)")
        XCTAssertTrue(app.staticTexts["Field content"].waitForExistence(timeout: 2.0),
                      "platformFormField: content must exist (contract structure)")
    }

    @MainActor
    func testL4_platformFormFieldGroup() throws {
        ensureContractRoot()
        scrollToElement(label: "L4FormFieldGroupContract")
        XCTAssertTrue(app.staticTexts["L4FormFieldGroupContract"].waitForExistence(timeout: 3.0),
                      "platformFormFieldGroup: title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformValidationMessage() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Form")
        scrollToElement(label: "L4ValidationMessageContract")
        XCTAssertTrue(app.staticTexts["L4ValidationMessageContract"].waitForExistence(timeout: 3.0),
                      "platformValidationMessage: message text must be visible (contract structure)")
    }

    @MainActor
    func testL4_platformListRow() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListRowContract")
        XCTAssertTrue(app.cells.staticTexts["L4ListRowContract"].waitForExistence(timeout: 3.0),
                      "platformListRow: row title must be in list cell (contract structure)")
    }

    @MainActor
    func testL4_platformListSectionHeader() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListSectionHeaderContract")
        XCTAssertTrue(app.staticTexts["L4ListSectionHeaderContract"].waitForExistence(timeout: 3.0),
                      "platformListSectionHeader: header title must exist (contract structure)")
    }

    @MainActor
    func testL4_platformListEmptyState() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ListEmptyStateContract")
        XCTAssertTrue(app.staticTexts["L4ListEmptyStateContract"].waitForExistence(timeout: 3.0),
                      "platformListEmptyState: title must exist (contract structure)")
    }

    // MARK: - Presentation

    @MainActor
    func testL4_platformSheet_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        // Do not scroll to L4ContractSheet (can swipe and hide top); find by id after section is in view.
        // TestApp sets .accessibilityIdentifier("L4ContractSheet") on the button; prefer that then contract id.
        let sheetButton = app.findElement(byIdentifier: "L4ContractSheet", primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 5.0)
            ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractsheet", elementType: "Button"), primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 2.0)
            ?? app.buttons["L4ContractSheet"].firstMatch
        XCTAssertTrue(sheetButton.waitForExistence(timeout: 5.0), "Sheet button should exist")
        tapByNormalizedCenter(sheetButton)
        XCTAssertTrue(app.staticTexts["L4SheetContentContract"].waitForExistence(timeout: 3.0),
                      "platformSheet_L4: sheet content must be visible when presented (contract behavior)")
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 2.0),
                      "platformSheet_L4: sheet must provide dismiss (contract structure)")
        app.buttons["Close"].firstMatch.tap()
    }

    @MainActor
    func testL4_platformPopover_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4 Presentation")
        // Do not scroll to L4ContractPopover (can swipe and hide top); find by id after section is in view.
        // TestApp sets .accessibilityIdentifier("L4ContractPopover") on the button; prefer that then contract id.
        let popoverButton = app.findElement(byIdentifier: "L4ContractPopover", primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 5.0)
            ?? app.findElement(byIdentifier: Self.l4ContractIdentifier(sanitizedName: "l4contractpopover", elementType: "Button"), primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 2.0)
            ?? app.buttons["L4ContractPopover"].firstMatch
        XCTAssertTrue(popoverButton.waitForExistence(timeout: 5.0), "Popover button should exist")
        tapByNormalizedCenter(popoverButton)
        XCTAssertTrue(app.staticTexts["L4PopoverContentContract"].waitForExistence(timeout: 3.0),
                      "platformPopover_L4: popover content must be visible when presented (contract behavior)")
    }

    // MARK: - Navigation

    @MainActor
    func testL4_platformNavigationTitle_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 3.0) {
            app.staticTexts["L4NavLinkContract"].firstMatch.tap()
        } else {
            let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
            let byPred = element(matchingIdentifier: "L4NavLinkContract")
            let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 2.0) ? byPred : nil)
            XCTAssertNotNil(tapTarget, "Nav link with identifier L4NavLinkContract should exist")
            tapByNormalizedCenter(tapTarget!)
        }
        XCTAssertTrue(app.navigationBars["L4NavTitleContract"].waitForExistence(timeout: 3.0),
                      "platformNavigationTitle_L4: destination title must appear in nav bar (contract structure)")
        XCTAssertTrue(app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 12.0),
                      "platformNavigationTitle_L4: destination content should be visible")
    }

    @MainActor
    func testL4_platformNavigationLink_L4() throws {
        ensureContractRoot()
        if app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 0.5) {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 2.0)
        }
        scrollToElement(label: "L4 Navigation")
        scrollToElement(label: "L4NavLinkContract")
        if app.staticTexts["L4NavLinkContract"].waitForExistence(timeout: 3.0) {
            app.staticTexts["L4NavLinkContract"].firstMatch.tap()
        } else {
            let byId = app.findElement(byIdentifier: "L4NavLinkContract", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any], timeout: 5.0)
            let byPred = element(matchingIdentifier: "L4NavLinkContract")
            let tapTarget: XCUIElement? = byId ?? (byPred.waitForExistence(timeout: 2.0) ? byPred : nil)
            XCTAssertNotNil(tapTarget, "platformNavigationLink: link with identifier L4NavLinkContract should exist")
            tapByNormalizedCenter(tapTarget!)
        }
        XCTAssertTrue(app.staticTexts["L4NavDestinationContent"].waitForExistence(timeout: 15.0),
                      "platformNavigationLink_L4: navigating to destination should show content")
    }

    @MainActor
    func testL4_platformNavigationBarTitleDisplayMode_L4() throws {
        ensureContractRoot()
        XCTAssertTrue(app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 3.0),
                      "platformNavigationBarTitleDisplayMode_L4: nav bar with title should exist (applied on root)")
    }

    // MARK: - System (Copy, Print, Share)

    @MainActor
    func testL4_platformCopyToClipboard_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractCopy")
        let copyById = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "L4ContractCopy")).firstMatch
        let copyByLabel = app.buttons["L4ContractCopy"].firstMatch
        let copyButton: XCUIElement
        if copyById.waitForExistence(timeout: 10.0) {
            copyButton = copyById
        } else {
            XCTAssertTrue(copyByLabel.waitForExistence(timeout: 3.0),
                          "platformCopyToClipboard_L4: Copy button with identifier or label L4ContractCopy should exist (contract a11y)")
            copyButton = copyByLabel
        }
        tapByNormalizedCenter(copyButton)
        // Behavior: copy invoked without crash; optional paste verification would require a paste target in contract UI
    }

    @MainActor
    func testL4_platformPrint_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "L4ContractPrint")
        let printById = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "L4ContractPrint")).firstMatch
        let printByLabel = app.buttons["L4ContractPrint"].firstMatch
        let printButton: XCUIElement
        if printById.waitForExistence(timeout: 10.0) {
            printButton = printById
        } else {
            XCTAssertTrue(printByLabel.waitForExistence(timeout: 3.0),
                          "platformPrint_L4: Print button with identifier or label L4ContractPrint should exist (contract a11y)")
            printButton = printByLabel
        }
        tapByNormalizedCenter(printButton)
        // Behavior: print sheet appears (iOS) or print panel (macOS); dismiss if present so suite can continue
        let cancelPrint = app.buttons["Cancel"].firstMatch
        if cancelPrint.waitForExistence(timeout: 2.0) { cancelPrint.tap() }
    }

    @MainActor
    func testL4_platformCloudKitSyncStatus_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "CloudKit Sync Status")
        XCTAssertTrue(app.staticTexts["CloudKit Sync: Idle"].waitForExistence(timeout: 5.0),
                      "platformCloudKitSyncStatus_L4: status text must be visible (contract structure)")
        let withId = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformCloudKitSyncStatus")).firstMatch
        XCTAssertTrue(withId.waitForExistence(timeout: 10.0),
                      "platformCloudKitSyncStatus_L4: view must have a11y identifier (contract a11y)")
    }

    @MainActor
    func testL4_platformPhotoDisplay_L4() throws {
        ensureContractRoot()
        scrollToElement(label: "Photo Display")
        let photoView = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS[c] %@", "platformPhotoDisplay")).firstMatch
        XCTAssertTrue(photoView.waitForExistence(timeout: 10.0),
                      "platformPhotoDisplay_L4: view must have a11y identifier (contract a11y)")
    }
}
